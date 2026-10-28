CREATE TABLE Masukan_Evaluasi (
  ID_Masukan   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  Uraian       TEXT NOT NULL,
  Tanggal      DATE NOT NULL,
  ID_Pengguna  INT UNSIGNED NOT NULL,
  CONSTRAINT pk_masukan PRIMARY KEY (ID_Masukan),
  CONSTRAINT fk_masukan_pengguna FOREIGN KEY (ID_Pengguna)
    REFERENCES Pengguna (ID_Pengguna)
);

SET @id_pencatat := (SELECT MIN(ID_Pengguna) FROM Pengguna WHERE Peran = 'Admin');
INSERT INTO Masukan_Evaluasi (ID_Masukan, Uraian, Tanggal, ID_Pengguna)
SELECT ID_Feedback, Isi_Masukan, Tanggal, @id_pencatat FROM Feedback_Menu;

ALTER TABLE Feedback_Aspek DROP FOREIGN KEY fk_aspek_feedback;
ALTER TABLE Feedback_Menu
  MODIFY ID_Feedback INT UNSIGNED NOT NULL,
  DROP COLUMN Isi_Masukan,
  DROP COLUMN Tanggal;
ALTER TABLE Feedback_Menu
  CHANGE ID_Feedback ID_Masukan INT UNSIGNED NOT NULL,
  ADD CONSTRAINT fk_feedback_masukan FOREIGN KEY (ID_Masukan)
    REFERENCES Masukan_Evaluasi (ID_Masukan) ON DELETE CASCADE;
ALTER TABLE Feedback_Aspek
  CHANGE ID_Feedback ID_Masukan INT UNSIGNED NOT NULL,
  ADD CONSTRAINT fk_aspek_feedback FOREIGN KEY (ID_Masukan)
    REFERENCES Feedback_Menu (ID_Masukan) ON DELETE CASCADE;

CREATE TABLE Laporan_Ketidaksesuaian (
  ID_Masukan            INT UNSIGNED NOT NULL,
  Jenis_Ketidaksesuaian VARCHAR(100) NOT NULL,
  Hasil_Pemeriksaan     TEXT NULL,
  Status_Tindak_Lanjut  ENUM('Baru','Diperiksa','Ditindaklanjuti','Selesai')
                        NOT NULL DEFAULT 'Baru',
  ID_Menu               INT UNSIGNED NULL,
  ID_Bahan              INT UNSIGNED NULL,
  CONSTRAINT pk_laporan PRIMARY KEY (ID_Masukan),
  CONSTRAINT fk_laporan_masukan FOREIGN KEY (ID_Masukan)
    REFERENCES Masukan_Evaluasi (ID_Masukan) ON DELETE CASCADE,
  CONSTRAINT fk_laporan_menu  FOREIGN KEY (ID_Menu)
    REFERENCES Menu_Harian (ID_Menu),
  CONSTRAINT fk_laporan_bahan FOREIGN KEY (ID_Bahan)
    REFERENCES Bahan_Pangan (ID_Bahan),
  CONSTRAINT ck_laporan_objek CHECK (ID_Menu IS NOT NULL OR ID_Bahan IS NOT NULL),
  CONSTRAINT ck_laporan_status CHECK (Status_Tindak_Lanjut = 'Baru'
                                      OR Hasil_Pemeriksaan IS NOT NULL)
);

DELIMITER $$
CREATE TRIGGER trg_feedback_disjoint BEFORE INSERT ON Feedback_Menu
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM Laporan_Ketidaksesuaian WHERE ID_Masukan = NEW.ID_Masukan) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Masukan sudah tercatat sebagai laporan';
  END IF;
END$$
CREATE TRIGGER trg_laporan_disjoint BEFORE INSERT ON Laporan_Ketidaksesuaian
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM Feedback_Menu WHERE ID_Masukan = NEW.ID_Masukan) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Masukan sudah tercatat sebagai feedback';
  END IF;
END$$
DELIMITER ;
