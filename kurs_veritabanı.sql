
CREATE DATABASE KursYonetimDB;
USE KursYonetimDB;

-- 1. TABLO: Kullanıcılar (Öğrenci ve Eğitmenler ortak tutulup 5NF gereği atomik yapı korunur)
CREATE TABLE Kullanici (
    KullaniciID INT AUTO_INCREMENT PRIMARY KEY,
    Ad VARCHAR(50) NOT NULL,
    Soyad VARCHAR(50) NOT NULL,
    Eposta VARCHAR(100) NOT NULL UNIQUE,
    KullaniciTipi ENUM('Ogrenci', 'Egitmen') DEFAULT 'Ogrenci'
);

-- 2. TABLO: Kurslar
CREATE TABLE Kurs (
    KursID INT AUTO_INCREMENT PRIMARY KEY,
    KursAdi VARCHAR(100) NOT NULL,
    Kredi INT NOT NULL,
    Fiyat DECIMAL(10,2) DEFAULT 0.00
);

-- 3. TABLO: Eğitmen-Kurs İlişkisi (Çoka Çok ilişkiyi ayırarak 4NF ve 5NF kurallarını sağlıyoruz)
CREATE TABLE KursEgitmen (
    EgitmenID INT,
    KursID INT,
    PRIMARY KEY (EgitmenID, KursID),
    FOREIGN KEY (EgitmenID) REFERENCES Kullanici(KullaniciID) ON DELETE CASCADE,
    FOREIGN KEY (KursID) REFERENCES Kurs(KursID) ON DELETE CASCADE
);

-- 4. TABLO: Kurs Kayıtları (Öğrencinin kursa kaydı)
CREATE TABLE Kayit (
    KayitID INT AUTO_INCREMENT PRIMARY KEY,
    OgrenciID INT NOT NULL,
    KursID INT NOT NULL,
    KayitTarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    Durum ENUM('Devam Ediyor', 'Tamamlandi') DEFAULT 'Devam Ediyor',
    FOREIGN KEY (OgrenciID) REFERENCES Kullanici(KullaniciID) ON DELETE CASCADE,
    FOREIGN KEY (KursID) REFERENCES Kurs(KursID) ON DELETE CASCADE,
    UNIQUE(OgrenciID, KursID) -- Bir öğrenci bir kursa sadece bir kez kaydolabilir
);

-- 5. TABLO: Sertifikalar (Kayıt tablosuna %100 bağımlıdır, transitif bağımlılık engellenmiştir)
CREATE TABLE Sertifika (
    SertifikaID INT AUTO_INCREMENT PRIMARY KEY,
    KayitID INT NOT NULL UNIQUE,
    SertifikaKodu VARCHAR(50) NOT NULL UNIQUE,
    VerilisTarihi DATE NOT NULL,
    FOREIGN KEY (KayitID) REFERENCES Kayit(KayitID) ON DELETE CASCADE
);


-- Sık arama yapılan Eposta ve Sertifika Kodu sütunlarına indeks ekliyoruz.
CREATE INDEX idx_kullanici_eposta ON Kullanici(Eposta);
CREATE INDEX idx_sertifika_kodu ON Sertifika(SertifikaKodu);


-- Öğrencilerin kazandığı sertifikaları detaylı olarak listeler.
CREATE VIEW vw_OgrenciSertifikalari AS
SELECT 
    k.Ad, 
    k.Soyad, 
    kr.KursAdi, 
    s.SertifikaKodu, 
    s.VerilisTarihi
FROM Kullanici k
JOIN Kayit ky ON k.KullaniciID = ky.OgrenciID
JOIN Kurs kr ON ky.KursID = kr.KursID
JOIN Sertifika s ON ky.KayitID = s.KayitID;


-- Yeni bir kurs kaydı oluşturur, hata yönetimini veritabanı seviyesinde yapar.
DELIMITER //
CREATE PROCEDURE sp_YeniKayitOlustur(IN p_OgrenciID INT, IN p_KursID INT)
BEGIN
    INSERT INTO Kayit (OgrenciID, KursID, Durum)
    VALUES (p_OgrenciID, p_KursID, 'Devam Ediyor');
END //
DELIMITER ;


-- Öğrencinin kurs durumu 'Tamamlandi' olarak güncellendiğinde OTOMATİK sertifika oluşturur.
DELIMITER //
CREATE TRIGGER trg_SertifikaOtomatikOlustur
AFTER UPDATE ON Kayit
FOR EACH ROW
BEGIN
    IF NEW.Durum = 'Tamamlandi' AND OLD.Durum != 'Tamamlandi' THEN
        INSERT INTO Sertifika (KayitID, SertifikaKodu, VerilisTarihi)
        VALUES (NEW.KayitID, UUID(), CURDATE());
    END IF;
END //
DELIMITER ;
