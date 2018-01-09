Import Taxi;

#WORKUNIT('name', 'Taxi Data:Testing');

taxiData := Taxi.Files.ETL.inFile;
NYC_EAST_BOUND := -71.777491;
NYC_WEST_BOUND := -79.762590;
NYC_NORTH_BOUND := 45.015865;
NYC_SOUTH_BOUND := 40.477399;

Taxi.Files.Validation.YellowLayout MakeValidationRec(Taxi.Files.ETL.YellowLayout inRec) := TRANSFORM
        SELF.is_good_passenger_count := inRec.passenger_count > 0;
        SELF.is_valid_vendor_id := inRec.VendorID IN [1, 2];
        SELF.pickup_in_bounding_box := ( inRec.pickup_latitude BETWEEN NYC_SOUTH_BOUND AND NYC_NORTH_BOUND ) 
                                        AND ( inRec.pickup_longitude BETWEEN NYC_WEST_BOUND AND NYC_EAST_BOUND );
        SELF.dropoff_in_bounding_box := ( inRec.dropoff_latitude BETWEEN NYC_SOUTH_BOUND AND NYC_NORTH_BOUND ) 
                                        AND ( inRec.dropoff_longitude BETWEEN NYC_WEST_BOUND AND NYC_EAST_BOUND );
        SELF.is_valid_record := SELF.is_good_passenger_count AND SELF.is_valid_vendor_id
                                AND SELF.pickup_in_bounding_box AND SELF.dropoff_in_bounding_box;
        SELF := inRec;
END;

validatedData := PROJECT
(
    taxiData,
    MakeValidationRec(LEFT)
);

OUTPUT(validatedData, NAMED('validatedData'));
OUTPUT(validatedData(NOT is_valid_record), NAMED('invalidData'));