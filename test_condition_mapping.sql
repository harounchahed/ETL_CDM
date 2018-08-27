SELECT  
			ROW_NUMBER() OVER (PARTITION BY LEFT(D.code, 1) ORDER BY D.code),  
			D.code as ICD , 
			D.txt as condition_source_name, 
			D.frequency_per_thousand 
FROM
	(SELECT  SD.icd_clean as code, SD.secondary_diag_t as txt, 
	convert(float, count(SD.icd_clean)) * 1000 / (Select 
			(select count(*) from Saphire_KTPH.dbo.t_secondary_diagnosis)
			+
			(select count(*) from Saphire_KTPH.dbo.t_primary_diagnosis))   as frequency_per_thousand  
	FROM Saphire_KTPH.dbo.t_secondary_diagnosis SD
	GROUP BY SD.icd_clean, SD.secondary_diag_t 
	UNION 
	(SELECT  PD.icd_clean as code, PD.primary_diag_t as txt, 
	convert(float, count(PD.icd_clean)) * 1000 / (Select 
			(select count(*) from Saphire_KTPH.dbo.t_secondary_diagnosis)
			+
			(select count(*) from Saphire_KTPH.dbo.t_primary_diagnosis))   as frequency_per_thousand  
	FROM Saphire_KTPH.dbo.t_primary_diagnosis PD
	GROUP BY PD.icd_clean, PD.primary_diag_t)) D  
LEFT OUTER JOIN (SELECT DISTINCT CO.condition_source_value, CO.condition_concept_id FROM OHDSI_KTPH.dbo.condition_occurrence CO) CO
ON D.code = CO.condition_source_value 
COLLATE SQL_Latin1_General_CP1_CI_AS
LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C 
ON CO.condition_concept_id = C.concept_id 
where condition_concept_id is null ; 
--ORDER BY NEWID() ; 
