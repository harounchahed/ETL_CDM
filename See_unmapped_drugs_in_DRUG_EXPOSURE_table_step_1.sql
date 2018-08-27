SELECT IMO.drug_inpat_order_ingred_clean, IMO.drug_inpat_order_unclean, COUNT(IMO.drug_inpat_order_ingred_clean) as count_unmapped_drugs
FROM Saphire_KTPH.dbo.t_inpatient_med_order IMO
	LEFT OUTER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD 
	ON IMO.encounter_id = VISD.encounter_id
		COLLATE SQL_Latin1_General_CP1_CI_AS 
		AND IMO.pat_type_cd = VISD.pat_type_cd
		COLLATE SQL_Latin1_General_CP1_CI_AS 
	LEFT OUTER JOIN OHDSI_KTPH.dbo.visit_occurrence VO
	ON VISD.visit_occurrence_id = VO.visit_occurrence_id  
	LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
	ON IMO.drug_inpat_order_ingred_clean = C.concept_name 
	COLLATE SQL_Latin1_General_CP1_CI_AS 
	/* ON CAST (IMO.drug_inpat_order_clean_cd as VARCHAR(100)) = C.concept_code */
	AND C.domain_id = 'Drug' 
WHERE C.concept_id IS NULL
GROUP BY IMO.drug_inpat_order_ingred_clean, IMO.drug_inpat_order_unclean 
ORDER BY COUNT(IMO.drug_inpat_order_ingred_clean) DESC  ; 
