
-------------------------------------------------------MVP------------------------------------------------------------------------

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi,
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS provider_name,
	SUM(CASE WHEN(CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name)) = CONCAT(nppes_provider_first_name, ' ', 	nppes_provider_last_org_name) THEN total_claim_count END) AS prescriber_total
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY npi,CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name)
ORDER BY prescriber_total DESC;

							             --2nd Attempt--

SELECT DISTINCT npi,
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS provider_name,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY npi, CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name)
ORDER BY total_claims DESC;

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT DISTINCT CONCAT(nppes_provider_first_name, ' ', nppes_provider_mi) AS provider_name,
	nppes_provider_last_org_name AS org_name,
	specialty_description AS specialty,
	SUM(CASE WHEN(CONCAT(nppes_provider_first_name, ' ', nppes_provider_mi)) = CONCAT(nppes_provider_first_name, ' ', nppes_provider_mi) THEN total_claim_count END) AS prescriber_total
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY CONCAT(nppes_provider_first_name, ' ', nppes_provider_mi), org_name, specialty
ORDER BY prescriber_total DESC;

							              --2nd attempt--
SELECT DISTINCT npi,
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_mi) AS provider_name,
	nppes_provider_last_org_name AS provider_last_name,
	specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY npi, CONCAT(nppes_provider_first_name, ' ', nppes_provider_mi), nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY specialty
ORDER BY total_claims DESC;

--     b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescription
LEFT JOIN prescriber
USING(npi)
INNER JOIN drug
ON drug.drug_name = prescription.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty
ORDER BY total_claims DESC NULLS LAST;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description AS specialty,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
GROUP BY specialty
HAVING SUM(total_claim_count) IS NULL;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH opioid_raw AS (
SELECT specialty_description,
	SUM(total_claim_count) AS opioid_claims
FROM prescription
JOIN prescriber
USING(npi)
FULL JOIN drug
ON drug.drug_name = prescription.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY specialty_description),
claim_raw AS (
SELECT specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescription
JOIN prescriber
USING(npi)
GROUP BY specialty_description)
SELECT claim_raw.specialty_description,
	opioid_raw.opioid_claims,
	claim_raw.total_claims,
	ROUND((opioid_raw.opioid_claims::NUMERIC / claim_raw.total_claims::NUMERIC), 2) AS claim_percent
FROM claim_raw
JOIN opioid_raw
ON opioid_raw.specialty_description = claim_raw.specialty_description
ORDER BY claim_percent DESC;

                                           --2nd Attempt--

SELECT specialty_description,
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) / SUM(total_claim_count) * 100 AS percent_opioid
FROM prescriber
LEFT JOIN prescription
USING(npi)
LEFT JOIN drug
USING(drug_name)
GROUP BY specialty_description
ORDER BY percent_opioid DESC NULLS LAST;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name,
	SUM(total_drug_cost::money) AS total_drug_cost
FROM drug
LEFT JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC NULLS LAST;

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name,
	SUM(total_drug_cost::money) AS total_drug_cost,
	ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::money AS cost_per_day
FROM drug
LEFT JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC NULLS LAST;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
WITH new_drug_table AS (
	SELECT drug_name,
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type,
	total_drug_cost::money
FROM drug
LEFT JOIN prescription
USING(drug_name)
)
SELECT 
	SUM(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END) AS opioid_total,
	SUM(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END) AS antibiotic_total
FROM new_drug_table;



SELECT drug_name,
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type,
	SUM(total_drug_cost)::MONEY AS total_cost
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY drug_type, drug_name
ORDER BY total_cost DESC;


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa,
	cbsaname,
	SUM(population) AS population
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsa,cbsaname
ORDER BY population DESC;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT population.fipscounty,
	county,
	state,
	population,
	cbsa
FROM population
FULL JOIN cbsa
USING(fipscounty)
INNER JOIN fips_county
ON population.fipscounty = fips_county.fipscounty
WHERE cbsa IS NULL
ORDER BY population DESC;

                                                      --OR--

SELECT county,
	population
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY population DESC;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, 
	total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, 
	total_claim_count,
	opioid_drug_flag
FROM prescription
LEFT JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name, 
	total_claim_count,
	opioid_drug_flag,
	nppes_provider_first_name AS provider_first_name,
	nppes_provider_last_org_name AS provider_last_name
FROM prescription
FULL JOIN drug
USING(drug_name)
LEFT JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opioid_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi,
drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi,
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS prescriber_name,
	drug_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name), drug_name 
ORDER BY npi;
	
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT prescriber.npi,
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS prescriber_name,
	drug_name,
	total_claim_count AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(drug_name, npi)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claims DESC NULLS LAST;

                                                    --2nd Attempt--

SELECT
	npi
	,drug.drug_name
	,COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claims DESC;
-------------------------------------------------------BONUS---------------------------------------------------------------------

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(npi)
FROM(
	SELECT npi
	FROM prescriber
	EXCEPT
	SELECT npi
	FROM prescription);

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT drug_name,
	COUNT(drug_name) AS count
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description LIKE 'Family Practice'
GROUP BY drug_name
ORDER BY count DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT drug_name,
	COUNT(drug_name) AS count
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description LIKE 'Cardiology'
GROUP BY drug_name
ORDER BY count DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT drug_name,
	COUNT(drug_name) AS count
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description LIKE 'Family Practice'
	OR specialty_description LIKE 'Cardiology'
GROUP BY drug_name
ORDER BY count DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT npi,
	drug_name,
	nppes_provider_first_name AS provider_name,
	nppes_provider_mi AS mi,
	total_claim_count AS claim_count,
	nppes_provider_city AS city
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE nppes_provider_city LIKE 'NASHVILLE'
ORDER BY total_claim_count DESC
LIMIT 5;
	
--     b. Now, report the same for Memphis.
SELECT
    npi,
    drug_name,
    nppes_provider_first_name AS provider_name,
    nppes_provider_mi,
    total_claim_count AS total_claims,
    nppes_provider_city AS city
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE nppes_provider_city LIKE 'MEMPHIS'
ORDER BY total_claims DESC
LIMIT 5;

--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT
    npi,
    drug_name,
    nppes_provider_first_name AS provider_name,
    nppes_provider_mi,
    total_claim_count AS total_claims,
    nppes_provider_city AS city
FROM prescription
LEFT JOIN prescriber
USING(npi)
WHERE nppes_provider_city LIKE 'NASHVILLE'
	OR nppes_provider_city LIKE 'MEMPHIS'
	OR nppes_provider_city LIKE 'KNOXVILLE'
	OR nppes_provider_city LIKE 'CHATTANOOGA'
ORDER BY total_claims DESC
LIMIT 5;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT DISTINCT(fipscounty)
FROM overdose_deaths;

SELECT county,
	overdose_deaths, year
FROM overdose_deaths
JOIN fips_county
ON overdose_deaths.fipscounty::INTEGER = fips_county.fipscounty::INTEGER
WHERE overdose_deaths > (SELECT AVG(overdose_deaths) FROM overdose_deaths);

-- 5.
--     a. Write a query that finds the total population of Tennessee.
SELECT SUM(population)
FROM population;

--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT county,
	population,
	ROUND((population / (SELECT SUM(population)
	FROM population) * 100), 2) AS percentage
FROM population
JOIN fips_county
USING(fipscounty)
GROUP BY population, fips_county.county
ORDER BY percentage DESC;

------------------------------------------------GROUPING SETS---------------------------------------------------------------

-- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 
SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description;

-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:
SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY prescriber.specialty_description
UNION ALL 
SELECT ' ',
	SUM(prescription.total_claim_count)
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management');

-- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.

SELECT COALESCE(specialty_description, ' '),
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
	(specialty_description),
	()
	);

-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:
SELECT COALESCE(specialty_description, ' ') AS specialty_description,
	COALESCE(opioid_drug_flag, ' ') AS opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
	(opioid_drug_flag),
	(specialty_description),
	()
	);

-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?
SELECT COALESCE(specialty_description, ' ') AS specialty_description,
	COALESCE(opioid_drug_flag, ' ') AS opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP (
	opioid_drug_flag,
	specialty_description
	);

-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?
SELECT COALESCE(specialty_description, ' ') AS specialty_description,
	COALESCE(opioid_drug_flag, ' ') AS opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP (
	specialty_description,
	opioid_drug_flag
	);

-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
SELECT COALESCE(specialty_description, ' ') AS specialty_description,
	COALESCE(opioid_drug_flag, ' ') AS opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE (specialty_description, opioid_drug_flag);

-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- The end result of this question should be a table formatted like this:

-- city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -----------|-------|--------|-----------|--------|---------|-----------|
-- CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
-- KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
-- MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
-- NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

-- For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
-- 	CREATE EXTENSION tablefunc;
CREATE EXTENSION tablefunc;

SELECT *
FROM drug
WHERE generic_name ILIKE ANY(ARRAY['%CODEINE%', '%FENTANYL%', '%HYDROCODONE%', '%MORPHINE%', '%OXYCODONE%', '%OXYMORPHONE%']);

SELECT *
FROM crosstab(
$$
SELECT city, opioid_type, total_claims FROM (
SELECT nppes_provider_city AS city,
	CASE
		WHEN drug_name ILIKE '%CODEINE%' THEN 'codiene'
		WHEN drug_name ILIKE '%FENTANYL%' THEN 'fentanyl'
		WHEN drug_name ILIKE '%HYDROCODONE%' THEN 'hydrocodone'
		WHEN drug_name ILIKE '%MORPHINE%' THEN 'morphine'
		WHEN drug_name ILIKE '%OXYCODONE%' THEN 'oxycodone'
		WHEN drug_name ILIKE '%OXYMORPHONE%' THEN 'oxymorphone'
		ELSE 'other'
	END AS opioid_type,
	SUM(total_claim_count) AS total_claims
FROM prescription
JOIN prescriber
USING(npi)
WHERE drug_name ILIKE ANY(ARRAY['%CODEINE%', '%FENTANYL%', '%HYDROCODONE%', '%MORPHINE%', 	'%OXYCODONE%', '%OXYMORPHONE%']) 
	AND nppes_provider_city ILIKE ANY(ARRAY['CHATTANOOGA', 'KNOXVILLE', 'MEMPHIS', 			'NASHVILLE'])
GROUP BY opioid_type, city
ORDER BY city)
ORDER BY 1,2
$$,
$$
SELECT DISTINCT opioid_type FROM (
SELECT nppes_provider_city AS city,
	CASE
		WHEN drug_name ILIKE '%CODEINE%' THEN 'codiene'
		WHEN drug_name ILIKE '%FENTANYL%' THEN 'fentanyl'
		WHEN drug_name ILIKE '%HYDROCODONE%' THEN 'hydrocodone'
		WHEN drug_name ILIKE '%MORPHINE%' THEN 'morphine'
		WHEN drug_name ILIKE '%OXYCODONE%' THEN 'oxycodone'
		WHEN drug_name ILIKE '%OXYMORPHONE%' THEN 'oxymorphone'
		ELSE 'other'
	END AS opioid_type,
	SUM(total_claim_count) AS total_claims
FROM prescription
JOIN prescriber
USING(npi)
WHERE drug_name ILIKE ANY(ARRAY['%CODEINE%', '%FENTANYL%', '%HYDROCODONE%', '%MORPHINE%', 	'%OXYCODONE%', '%OXYMORPHONE%']) 
	AND nppes_provider_city ILIKE ANY(ARRAY['CHATTANOOGA', 'KNOXVILLE', 'MEMPHIS', 			'NASHVILLE'])
GROUP BY opioid_type, city
ORDER BY city)
ORDER BY 1
$$
) AS (
	city TEXT,
	codiene TEXT,
	fentanyl TEXT,
	hydrocodone TEXT,
	morphine TEXT,
	oxycodone TEXT,
	oxymorphone TEXT
);


-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
-- Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.
-- Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.
