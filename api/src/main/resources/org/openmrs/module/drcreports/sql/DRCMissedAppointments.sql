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
    -- Contact information from telephone person attribute
    (
        SELECT pa_contact.value
        FROM person_attribute pa_contact
        JOIN person_attribute_type pat_contact ON pa_contact.person_attribute_type_id = pat_contact.person_attribute_type_id
        WHERE pa_contact.person_id = per.person_id
          AND pa_contact.voided = 0
          AND pat_contact.uuid = '14d4f066-15f5-102d-96e4-000c29c2a5d7'
    ) AS `Contact`,
    -- Tracing Method from coded obs
    -- we are missing fr translation for the answers
    (
        SELECT cn_tracing.name
        FROM obs o_tracing
        JOIN concept c_tracing ON o_tracing.concept_id = c_tracing.concept_id
        JOIN concept_name cn_tracing ON o_tracing.value_coded = cn_tracing.concept_id
        WHERE o_tracing.person_id = per.person_id
          AND o_tracing.voided = 0
          AND c_tracing.uuid = '166456AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
          AND cn_tracing.concept_name_type = 'FULLY_SPECIFIED'
    ) AS `Méthode de Traçage`,
    -- Latest Appointment Date
    (
        SELECT DATE_FORMAT(MAX(pa.start_date_time), '%d/%m/%Y')
        FROM patient_appointment pa
        WHERE pa.patient_id = p.patient_id
          AND pa.voided = 0
          AND pa.start_date_time IS NOT NULL
    ) AS `Dernière Date de Rendez-vous`,
    -- Days elapsed since latest appointment
    (
        SELECT DATEDIFF(:onOrBefore, DATE(MAX(pa.start_date_time)))
        FROM patient_appointment pa
        WHERE pa.patient_id = p.patient_id
          AND pa.voided = 0
          AND pa.start_date_time IS NOT NULL
    ) AS `Jours Écoulés Depuis le Dernier Rendez-vous`,
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
WHERE 
    -- Filter by specific patient identifier type UUID
    pit.uuid = '9d6d1eec-2cd6-4637-a981-4a46b4b8b41f'
    -- Filter for patients who have appointments
    AND EXISTS (
        SELECT 1 FROM patient_appointment pa
        WHERE pa.patient_id = p.patient_id
          AND pa.voided = 0
          AND pa.start_date_time IS NOT NULL
    )
    -- Filter for patients whose latest appointment is at reporting date or in the past
    AND (
        SELECT MAX(pa.start_date_time)
        FROM patient_appointment pa
        WHERE pa.patient_id = p.patient_id
          AND pa.voided = 0
          AND pa.start_date_time IS NOT NULL
    ) <= :onOrBefore
    -- Ensure no visit exists after the latest appointment date
    AND NOT EXISTS (
        SELECT 1 FROM visit v
        WHERE v.patient_id = p.patient_id
          AND v.voided = 0
          AND v.date_started IS NOT NULL
          AND v.date_started > (
              SELECT MAX(pa.start_date_time)
              FROM patient_appointment pa
              WHERE pa.patient_id = p.patient_id
                AND pa.voided = 0
                AND pa.start_date_time IS NOT NULL
          )
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