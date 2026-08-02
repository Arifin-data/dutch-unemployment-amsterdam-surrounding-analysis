#CSV data van CBS laden
CREATE DATABASE kerncijfers;

USE kerncijfers;

SELECT * FROM kerncijfers_data;

DESCRIBE kerncijfers_data;

#Bestand kopieren waar we in gaan werken
CREATE TABLE kerncijfers_bu like kerncijfers_data;

INSERT INTO kerncijfers_bu
SELECT * FROM kerncijfers_data;

SELECT * FROM kerncijfers_bu;

#aanpassen kolomnaam
ALTER TABLE kerncijfers_data
RENAME COLUMN `ï»¿Regio` TO Regio;

ALTER TABLE kerncijfers_bu
RENAME COLUMN `ï»¿Regio` TO Regio;

SELECT DISTINCT Regio FROM kerncijfers_bu;

SELECT DISTINCT `Namen van meetwaarden` FROM kerncijfers_bu;

SELECT *
FROM kerncijfers_bu
WHERE `Namen van meetwaarden` = 'PotentiÃ«le beroepsbevolking 15-75 jaar (x 1.000 personen)';

SET SQL_SAFE_UPDATES = 0;

UPDATE kerncijfers_bu
SET `Namen van meetwaarden` =
REPLACE(
    `Namen van meetwaarden`,
    'PotentiÃ«le beroepsbevolking 15-75 jaar (x 1.000 personen)',
    'Potentiële beroepsbevolking 15-75 jaar (x 1.000 personen)'
);

SET SQL_SAFE_UPDATES = 1;

# transposen/pivoten kolommen in nwe tabel

CREATE TABLE kerncijfers_bu_pivot AS
SELECT
    Regio,
    Jaar,
    MAX(CASE
        WHEN `Namen van meetwaarden` = 'Werkloosheidspercentage (%)'
        THEN Meetwaarden
    END) AS Werkloosheidspercentage,

    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Werkzame beroepsbevolking 15-75 jaar  (x 1.000 personen)'
        THEN Meetwaarden
    END) AS Werkzame_beroepsbevolking,

    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Werkloze beroepsbevolking 15-75 jaar (x 1.000 personen)'
        THEN Meetwaarden
    END) AS Werkloze_beroepsbevolking,

    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Beroepsbevolking 15-75 jaar (x 1.000 personen)'
        THEN Meetwaarden
    END) AS Beroepsbevolking,
    
    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Potentiële beroepsbevolking 15-75 jaar (x 1.000 personen)'
        THEN Meetwaarden
    END) AS Potentiële_beroepsbevolking,
    
    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Arbeidsvolume (x 1.000 fte)'
        THEN Meetwaarden
    END) AS Arbeidsvolume,
    
    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Werkzame personen (x 1.000 personen)'
        THEN Meetwaarden
    END) AS Werkzame_personen,
    
    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Toegevoegde waarde (x mld euro)'
        THEN Meetwaarden
    END) AS Toegevoegde_waarde,
    
    MAX(CASE
        WHEN `Namen van meetwaarden` =  'Brp (x mld euro)'
        THEN Meetwaarden
    END) AS Brp,
    
    MAX(CASE
        WHEN `Namen van meetwaarden` LIKE 'Bruto arbeidsparticipatie (%)'
        THEN Meetwaarden
    END) AS Bruto_arbeidsparticipatie

FROM kerncijfers_bu
GROUP BY Regio, Jaar
ORDER BY Regio, Jaar;

SELECT * FROM kerncijfers_bu_pivot;

DESCRIBE kerncijfers_bu_pivot;

SELECT *
FROM kerncijfers_bu
WHERE `Namen van meetwaarden` = 'Arbeidsvolume (x 1.000 fte)';

#testen opvullen nulwaarden werkloosheid percentage

SELECT
    Regio,
    Jaar,
    Werkloze_beroepsbevolking,
    Beroepsbevolking,
    ROUND((Werkloze_beroepsbevolking / Beroepsbevolking) * 100, 0) AS NieuwPercentage
FROM kerncijfers_bu_pivot
WHERE Werkloosheidspercentage IS NULL;


#alvorens tabel te updaten, eerst kopie maken in kerncijfers_bu_pivotbewerkt
CREATE TABLE kerncijfers_bu_pivotbewerkt like kerncijfers_bu_pivot;

INSERT INTO kerncijfers_bu_pivotbewerkt
SELECT * FROM kerncijfers_bu_pivot;

SELECT * FROM kerncijfers_bu_pivotbewerkt; 

#updaten tabel kerncijfers_bu_pivotbewerkt kolom werkloosheidspercentage

SET SQL_SAFE_UPDATES = 0;

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloosheidspercentage = ROUND(
    (Werkloze_beroepsbevolking / Beroepsbevolking, 0)) * 100
WHERE Werkloosheidspercentage IS NULL;

SET SQL_SAFE_UPDATES = 1;

SELECT * FROM kerncijfers_bu_pivotbewerkt;

#testen vervangen waarden werklose beroepsbevolking voor 2 rijen vanwege nniet in lijn met vorige jaren

SELECT
    Regio,
    Jaar,
    Werkloze_beroepsbevolking,
    Beroepsbevolking,
    ROUND((Beroepsbevolking - Werkzame_Beroepsbevolking), 0) AS NieuwWaarde
FROM kerncijfers_bu_pivotbewerkt
WHERE Regio = 'Waterland' and Jaar = '2013';

SELECT
    Regio,
    Jaar,
    Werkloze_beroepsbevolking,
    Beroepsbevolking,
    ROUND((Beroepsbevolking - Werkzame_Beroepsbevolking), 0) AS NieuwWaarde
FROM kerncijfers_bu_pivotbewerkt
WHERE Regio = 'Zaanstreek' and Jaar = '2013';

SELECT
    Regio,
    Jaar,
    Werkloze_beroepsbevolking,
    Beroepsbevolking,
    ROUND((Beroepsbevolking - Werkzame_Beroepsbevolking), 0) AS NieuwWaarde
FROM kerncijfers_bu_pivotbewerkt
WHERE Regio = 'IJmond' and (Jaar = '2013' or Jaar = '2014');

#updaten deze waarden in kolom Werkloze_beroepsbevolking

SET SQL_SAFE_UPDATES = 0;

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloze_beroepsbevolking = ROUND((Beroepsbevolking - Werkzame_Beroepsbevolking), 0)
WHERE Regio = 'Waterland' and Jaar = '2013';

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloze_beroepsbevolking = ROUND((Beroepsbevolking - Werkzame_Beroepsbevolking), 0)
WHERE  Regio = 'Zaanstreek' and Jaar = '2013';

SET SQL_SAFE_UPDATES = 1;

#updaten waarden (%) in kolom Werkloosheidspercentage

SET SQL_SAFE_UPDATES = 0;

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloosheidspercentage = ROUND(
    (Werkloze_beroepsbevolking / Beroepsbevolking) * 100,0)
WHERE Regio = 'Waterland' and Jaar = '2013';

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloosheidspercentage = ROUND(
    (Werkloze_beroepsbevolking / Beroepsbevolking) * 100,0)
WHERE Regio = 'Zaanstreek' and Jaar = '2013';

SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloze_beroepsbevolking = ROUND((Beroepsbevolking - Werkzame_Beroepsbevolking), 0)
WHERE Regio = 'IJmond' and (Jaar = '2013' or Jaar = '2014');

UPDATE kerncijfers_bu_pivotbewerkt
SET Werkloosheidspercentage = ROUND(
    (Werkloze_beroepsbevolking / Beroepsbevolking) * 100,0)
WHERE Regio = 'IJmond' and (Jaar = '2013' or Jaar = '2014');


SET SQL_SAFE_UPDATES = 1;

# Deleten rijen waarbij de regio nederland is 

DELETE FROM kerncijfers_bu_pivotbewerkt
WHERE Regio = 'Nederland';

#ongedaan maken

INSERT INTO kerncijfers_bu_pivotbewerkt
SELECT *
FROM kerncijfers_bu_pivot
WHERE Regio = 'Nederland';

# verdere opschoning 
UPDATE kerncijfers_bu_pivotbewerkt
SET Jaar = '2016'
WHERE Jaar = '2016*';
SELECT * FROM kerncijfers_bu_pivotbewerkt;

UPDATE kerncijfers_bu_pivotbewerkt
SET Jaar = '2017'
WHERE Jaar = '2017*';

#Controleren of er duplicaten zijn in taben (niet aanwezig)
SELECT *, row_number() OVER(partition by Regio, Jaar) as Row_Num FROM kerncijfers_bu_pivotbewerkt;

#Aantal rijen aanwezig in tabel (38 Rijen)
SELECT *, row_number() OVER() as Row_Num FROM kerncijfers_bu_pivotbewerkt;

#Aantal jaren aanwezig in tabel (2013 tm 2017) 
SELECT DISTINCT Jaar FROM kerncijfers_bu_pivotbewerkt
Order by Jaar DESC;

ALTER TABLE kerncijfers_bu_pivotbewerkt
DROP COLUMN Arbeidsvolume,
DROP COLUMN Werkzame_personen,
DROP COLUMN Toegevoegde_waarde,
DROP COLUMN Brp,
DROP COLUMN Bruto_arbeidsparticipatie;

#Aantal Regio aanwezig in tabel (12 waaronderr Nederland) 
SELECT DISTINCT Regio FROM kerncijfers_bu_pivotbewerkt;

#Analyse jaar en regio met hoogste percentage werklooshekid
SELECT Regio, Jaar, Beroepsbevolking, Werkloosheidspercentage 
FROM kerncijfers_bu_pivotbewerkt
ORDER BY Werkloosheidspercentage Desc;

#Regio met hoogste gemiddelde percentage werklooshekid
SELECT Regio, ROUND(AVG(Beroepsbevolking),1) , ROUND(AVG(Werkloosheidspercentage),1)
FROM kerncijfers_bu_pivotbewerkt
GROUP BY Regio
ORDER BY AVG(Werkloosheidspercentage) Desc;

#Jaar met hoogste gemiddelde percentage werklooshekid (2014)
SELECT Jaar, ROUND(AVG(Beroepsbevolking),1) , ROUND(AVG(Werkloosheidspercentage),1)
FROM kerncijfers_bu_pivotbewerkt
GROUP BY Jaar
ORDER BY AVG(Werkloosheidspercentage) Desc;

SELECT * FROM kerncijfers_bu_pivotbewerkt;
