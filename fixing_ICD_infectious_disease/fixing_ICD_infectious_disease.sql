UPDATE Saphire_KTPH.dbo.t_primary_diagnosis 
SET icd_clean = Conv.[correct_ICD-9CM_code] 
FROM Saphire_KTPH.dbo.t_primary_diagnosis PD 
LEFT OUTER JOIN OHDSI_KTPH.dbo.table_of_coversion_of_infectious_disease CONV
ON CONV.ICD = PD.icd_clean 
COLLATE SQL_Latin1_General_CP1_CS_AS
AND CONV.condition_source_name = PD.primary_diag_cd 
COLLATE SQL_Latin1_General_CP1_CS_AS

	