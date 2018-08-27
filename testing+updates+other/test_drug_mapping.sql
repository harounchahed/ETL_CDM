SELECT DISTINCT DE.drug_source_value as clean_source_value,
				IMO.drug_inpat_order_unclean as unclean_source_value, 
				DE.drug_concept_id,
				C.concept_name  
FROM (SELECT DISTINCT DE.drug_source_value, DE.drug_concept_id FROM OHDSI_KTPH.dbo.drug_exposure DE) DE 
LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C 
ON DE.drug_concept_id = C. concept_id
LEFT OUTER JOIN (SELECT IMO.drug_inpat_order_unclean, IMO.drug_inpat_order_ingred_clean FROM Saphire_KTPH.dbo.t_inpatient_med_order IMO) IMO 
ON IMO.drug_inpat_order_ingred_clean = DE.drug_source_value
COLLATE SQL_Latin1_General_CP1_CI_AS ;