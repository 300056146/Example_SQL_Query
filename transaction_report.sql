SELECT 
    # basic transaction data 
    transaction_basic_info.transaction_creation_date AS 'Date Transaction Created',
    transaction_basic_info.transaction_pickup_date AS 'Pickup Date',
    transaction_basic_info.transaction_serial_no AS 'Load Number',
    # type of container the load was transported in 
    containers.container_type AS 'Container Type', 
    containers.quantity AS 'Container Count',
    # weight breakdown of the material being transported
    origin_total_weight.weight AS 'Origin Total Weight',
    display_devices.weight AS 'Display Devices (Monitors/TVs)', 
    computers.weight AS 'Computers (CPU)', 
    other_program.weight AS 'Other program material (Mixed)', 
    printers.weight AS 'Floor Standing Printers', 
    non_program.weight AS 'Non Program Material', 
    freon.weight AS 'Freon Bearing Material', 
    appliances.weight AS 'Small Appliances', 
    scraps.weight AS 'Scrap Metal', 
    garbage.weight AS 'Garbage', 
    batteries.weight AS 'Batteries', 
    reuse.weight AS 'Reuse', 
    comingled.weight AS 'Comingled Material',
    ink_toner_mail_back.weight AS 'Ink/Toner Mail Back',
    ink_toner.weight AS 'Ink/Toner',
    new_waste_categories.weight AS 'Uncaptured Waste Categories', 
    destination_total_weight.weight AS 'Destination Total Weight',	
    # basic info relating to the transaction's origin site 
    IF(origin.depot_type = 0, origin_type.description,
        depot_type.depot_type_en_description) AS 'Orign Type',
    origin.participant_org_name AS 'Origin Organization Name',
    origin.participant_serial_no AS 'Origin Site ID',
    origin.participant_ops_name AS 'Origin Site Name',
    IF(transaction_basic_info.transaction_origin_city = '', origin_address.city, transaction_basic_info.transaction_origin_city) AS 'Origin City',
    # basic info relating to the transaction's destination site 
    destionation_type.description AS 'Destination Type',
    destination.participant_org_name AS 'Destination Organization Name',
    destination.participant_serial_no AS 'Destination Site ID',
    destination.participant_ops_name AS 'Destination Site Name',
    IF(transaction_basic_info.transaction_destination_city = '', destination_address.city, transaction_basic_info.transaction_destination_city) AS 'Destination City',
    # basic info relating to the transaction's transporter
    transporter.participant_serial_no AS 'Transporter ID',
    transporter.participant_ops_name AS 'Transporter Name',
    # rates for each participant involved in the transaction
    transaction_basic_info.origin_invoicable_rate AS 'Origin Rate', 
    IF(destination.participant_type = 5, transaction_basic_info.destination_invoicable_rate, 0) AS 'Consolidation Center Rate',
    IF(destination.participant_type = 4, transaction_basic_info.destination_invoicable_rate, 0) AS 'Processor Rate',
    transaction_basic_info.transporter_invoicable_rate AS 'Transporter Rate', 
    # basic info relating to the status of a transaction 
    transaction_status_info.transaction_status_name AS 'Transaction Status', 
    origin_status.transaction_status_name AS 'Origin Status',
    transportation_status.transaction_status_name AS 'Transportation Status',
    destination_status.transaction_status_name AS 'Destination Status'
FROM
    transaction_basic_info
        LEFT JOIN 
    (SELECT   
        transaction_container_info.transactionID AS transactionID,
        IF(transaction_container_info.container_type_id = 8 OR transaction_container_info.container_type_id = 11 OR transaction_container_info.container_type_id = 28 OR transaction_container_info.container_type_id = 29, 'Bins', 
            IF(transaction_container_info.container_type_id = 3 OR transaction_container_info.container_type_id = 4, 'Pallets', 
            IF(transaction_container_info.container_type_id = 2, 'E-Bags', ''))) AS container_type, 
        SUM(transaction_container_info.quantity) AS quantity
    FROM transaction_container_info
    GROUP BY transaction_container_info.transactionID, container_type) AS containers ON transaction_basic_info.id = containers.transactionID
        LEFT JOIN
    participant AS transporter ON transaction_basic_info.transporters = transporter.id
        LEFT JOIN
    participant AS destination ON transaction_basic_info.destinations = destination.id
        LEFT JOIN
    participant_type AS destionation_type ON destionation_type.id = destination.participant_type
        LEFT JOIN 
    participant AS origin ON transaction_basic_info.origin = origin.id
        LEFT JOIN
    participant_type AS origin_type ON origin_type.id = origin.participant_type
        LEFT JOIN
    participant_depot_types AS depot_type ON depot_type.id = origin.depot_type
        LEFT JOIN
    participant_address AS origin_address ON origin.id = origin_address.participant_id 
        LEFT JOIN
    participant_address AS destination_address ON destination.id = destination_address.participant_id
        LEFT JOIN
    (transaction_load_details
        LEFT JOIN
    (SELECT   
        transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 1 
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS display_devices ON transaction_load_details.transactionID = display_devices.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 3
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS computers ON transaction_load_details.transactionID = computers.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 2
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS other_program ON transaction_load_details.transactionID = other_program.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 6
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS printers ON transaction_load_details.transactionID = printers.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 5
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS non_program ON transaction_load_details.transactionID = non_program.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 8
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS freon ON transaction_load_details.transactionID = freon.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 9
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS appliances ON transaction_load_details.transactionID = appliances.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 11
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS scraps ON transaction_load_details.transactionID = scraps.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 12
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS garbage ON transaction_load_details.transactionID = garbage.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 13
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS batteries ON transaction_load_details.transactionID = batteries.transactionID 
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 14
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS reuse ON transaction_load_details.transactionID = reuse.transactionID
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 23
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS comingled ON transaction_load_details.transactionID = comingled.transactionID
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 24
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS ink_toner_mail_back ON transaction_load_details.transactionID = ink_toner_mail_back.transactionID
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id = 25
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS ink_toner ON transaction_load_details.transactionID = ink_toner.transactionID
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_type_id > 25 
        AND transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS new_waste_categories ON transaction_load_details.transactionID = new_waste_categories.transactionID
        LEFT JOIN 
    (SELECT transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_measurer_id = 3
    GROUP BY transaction_load_details.transactionID) AS destination_total_weight ON transaction_load_details.transactionID = destination_total_weight.transactionID
            LEFT JOIN 
    (SELECT   
        transaction_load_details.transactionID AS transactionID,
        SUM(IF(transaction_load_details.weight_unit = 2,
            ROUND(transaction_load_details.weight * 1000, 3),
            ROUND(transaction_load_details.weight, 3))) AS weight
    FROM transaction_load_details
    WHERE transaction_load_details.waste_measurer_id = 1
    GROUP BY transaction_load_details.transactionID) AS origin_total_weight ON transaction_load_details.transactionID = origin_total_weight.transactionID) ON transaction_basic_info.id = transaction_load_details.transactionID
            LEFT JOIN 
    transaction_status_info ON transaction_basic_info.status_id = transaction_status_info.id
            LEFT JOIN 
    transaction_status_info AS origin_status ON transaction_basic_info.origin_status = origin_status.id
            LEFT JOIN 
    transaction_status_info AS transportation_status ON transaction_basic_info.transporter_status = transportation_status.id
            LEFT JOIN 
    transaction_status_info AS destination_status ON transaction_basic_info.destination_status = destination_status.id
WHERE transaction_basic_info.origin = origin.id
        AND transaction_basic_info.province_id = 21
        AND NOT (transaction_basic_info.status_id = 7)
        AND origin.is_test_data = 0 
        AND (transporter.is_test_data = 0 OR transaction_basic_info.transporters = 0)
        AND (destination.is_test_data = 0 OR transaction_basic_info.destinations = 0)
        AND YEAR(transaction_basic_info.transaction_creation_date) IN (:year:) # this command allowed user to filter out data from unwanted year(s) 
GROUP BY transaction_basic_info.transaction_serial_no 
ORDER BY 'Pickup Date'
LOCK IN SHARE MODE
