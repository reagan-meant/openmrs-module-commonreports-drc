SELECT 
    -- Combined given and middle name
    CONCAT_WS(' ', COALESCE(pn.given_name, ''), COALESCE(pn.middle_name, '')) AS `Prenom et Postnom du Patient`,
    COALESCE(pn.family_name, '') AS `Nom de Famille du Patient`,
    
    pi.identifier AS `Code TAR`,
    per.gender AS `Genre`,
    DATE_FORMAT(per.birthdate, '%d/%m/%Y') AS `Date de Naissance`,
    TIMESTAMPDIFF(YEAR, per.birthdate, CURDATE()) AS `Age`,
    CONCAT_WS(' ', 
        COALESCE(addr.city_village, ''),
        COALESCE(addr.address1, ''),
        COALESCE(addr.address2, ''),
        COALESCE(addr.state_province, ''),
        COALESCE(addr.country, '')
    ) AS `Provenance du Patient`,
    -- Enrollment Date (required)
    MAX(CASE WHEN c.uuid = '160555AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' THEN DATE_FORMAT(o.value_datetime, '%d/%m/%Y') END) AS `Date d'Enregistrement`,
    -- Latest Regimen (optional)
    MAX(CASE WHEN c.uuid = '164432AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' THEN cn.name END) AS `Dernier Régime`,
    -- Latest Visit Start Date
    (
        SELECT DATE_FORMAT(v.date_started, '%d/%m/%Y')
        FROM visit v
        WHERE v.patient_id = p.patient_id
          AND v.voided = 0
          AND v.date_started IS NOT NULL
        ORDER BY v.date_started DESC
        LIMIT 1
    ) AS `Date de Début de la Dernière Visite`,
    -- Latest Visit End Date (from the same visit as above)
    (
        SELECT DATE_FORMAT(v.date_stopped, '%d/%m/%Y')
        FROM visit v
        WHERE v.patient_id = p.patient_id
          AND v.voided = 0
          AND v.date_started IS NOT NULL
        ORDER BY v.date_started DESC
        LIMIT 1
    ) AS `Date de Fin de la Dernière Visite`
FROM 
    patient p
    INNER JOIN person_name pn ON p.patient_id = pn.person_id AND pn.voided = 0
    INNER JOIN person per ON p.patient_id = per.person_id AND p.voided = 0
    LEFT JOIN patient_identifier pi ON p.patient_id = pi.patient_id
    LEFT JOIN patient_identifier_type pit ON pi.identifier_type = pit.patient_identifier_type_id
    LEFT JOIN person_address addr ON per.person_id = addr.person_id
    -- Obs join
    LEFT JOIN obs o ON p.patient_id = o.person_id
        AND o.voided = 0
    -- Concept join
    LEFT JOIN concept c ON o.concept_id = c.concept_id
    LEFT JOIN concept_name cn ON o.value_coded = cn.concept_id 
        AND cn.concept_name_type = 'FULLY_SPECIFIED'
        AND cn.locale = 'en'
WHERE 
    -- Filter by specific patient identifier type UUID
    pit.uuid = '9d6d1eec-2cd6-4637-a981-4a46b4b8b41f'
    -- Only include patients who have an Enrollment Date obs
    AND EXISTS (
        SELECT 1 FROM obs o2
        JOIN concept c2 ON o2.concept_id = c2.concept_id
        WHERE o2.person_id = p.patient_id
          AND o2.voided = 0
          AND c2.uuid = '160555AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    )
GROUP BY 
    `Prenom et Postnom du Patient`,
    `Nom de Famille du Patient`,
    `Code TAR`,
    `Genre`,
    `Date de Naissance`,
    `Provenance du Patient`
ORDER BY 
    `Nom de Famille du Patient`, `Prenom et Postnom du Patient`;