SELECT person_id, count(drug_concept_id) 
FROM OHDSI_KTPH.dbo.DRUG_EXPOSURE d
INNER JOIN OHDSI_KTPH.dbo.CONCEPT_ANCESTOR ca 
ON d.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600712,21500148)
GROUP BY person_id, drug_exposure_start_date
HAVING count(drug_concept_id) > 1
ORDER BY person_id 
 ; 