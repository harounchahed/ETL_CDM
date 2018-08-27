WITH observation_period_table AS 
	(SELECT VO.person_id, DATEDIFF (year, MIN(VO.visit_start_date), MAX(VO.visit_end_date)) as observation_period_in_years
	FROM OHDSI_KTPH.dbo.visit_occurrence VO 
	GROUP BY VO.person_id 
	--ORDER BY DATEDIFF (year, MIN(VO.visit_start_date), MAX(VO.visit_end_date))
	) 
SELECT observation_period_in_years, count(observation_period_in_years) as patients_count
FROM observation_period_table 
GROUP BY observation_period_in_years
ORDER BY observation_period_in_years; 