import java.sql.*;

public class KursYonetimSistemi {

    // Veritabanı bağlantı bilgileri
    private static final String URL = "jdbc:mysql://localhost:3306/KursYonetimDB";
    private static final String USER = "root";       // Buraya kendi DB kullanıcı adını yaz
    private static final String PASSWORD = "1234";   // Buraya kendi DB şifreni yaz

    public static void main(String[] args) {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD)) {
            System.out.println("Veritabanina basariyla baglanildi!");


            ornekVeriEkle(conn);

            //  Stored Procedure Kullanarak Yeni Kayıt Oluşturma
            System.out.println("\n--- Stored Procedure Calistiriliyor ---");
            kursaKaydol(conn, 1, 1); // 1 ID'li ogrenci, 1 ID'li kursa kaydoluyor

            //  Trigger Testi: Kayıt durumunu 'Tamamlandi' olarak güncelle
            System.out.println("\n--- Kurs Durumu Guncelleniyor (Trigger Tetiklenecek) ---");
            kursuTamamla(conn, 1); // 1 numaralı kaydı tamamla

            //  View Kullanarak Sertifikaları Görüntüleme
            System.out.println("\n--- View Uzerinden Sertifikalar Cekiliyor ---");
            sertifikalariGoruntule(conn);

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    // METOTLAR

    private static void ornekVeriEkle(Connection conn) throws SQLException {
        // Hata almamak için var olan veriyi temizlemiyoruz, basitçe insert deniyoruz
        String sqlKullanici = "INSERT IGNORE INTO Kullanici (KullaniciID, Ad, Soyad, Eposta, KullaniciTipi) VALUES (1, 'Ahmet', 'Yilmaz', 'ahmet@email.com', 'Ogrenci')";
        String sqlKurs = "INSERT IGNORE INTO Kurs (KursID, KursAdi, Kredi, Fiyat) VALUES (1, 'Ileri Java Egitimi', 5, 1500.00)";

        try (Statement stmt = conn.createStatement()) {
            stmt.executeUpdate(sqlKullanici);
            stmt.executeUpdate(sqlKurs);
        }
    }

    private static void kursaKaydol(Connection conn, int ogrenciID, int kursID) {
        String callProsedur = "{CALL sp_YeniKayitOlustur(?, ?)}";

        try (CallableStatement cstmt = conn.prepareCall(callProsedur)) {
            cstmt.setInt(1, ogrenciID);
            cstmt.setInt(2, kursID);
            cstmt.execute();
            System.out.println("Ogrenci kursa basariyla kaydedildi.");
        } catch (SQLException e) {
            System.out.println("Kayit sirasinda hata veya zaten kayitli: " + e.getMessage());
        }
    }

    private static void kursuTamamla(Connection conn, int kayitID) {
        String sql = "UPDATE Kayit SET Durum = 'Tamamlandi' WHERE KayitID = ?";

        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, kayitID);
            int affectedRows = pstmt.executeUpdate();
            if (affectedRows > 0) {
                System.out.println("Kurs tamamlandi. Trigger sayesinde sertifika otomatik olusturuldu!");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private static void sertifikalariGoruntule(Connection conn) {
        String sqlView = "SELECT * FROM vw_OgrenciSertifikalari";

        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sqlView)) {

            while (rs.next()) {
                System.out.println("Ad Soyad: " + rs.getString("Ad") + " " + rs.getString("Soyad") +
                        " | Kurs: " + rs.getString("KursAdi") +
                        " | Sertifika Kodu: " + rs.getString("SertifikaKodu") +
                        " | Tarih: " + rs.getDate("VerilisTarihi"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}

