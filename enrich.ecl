IMPORT Taxi;
IMPORT Std;

#WORKUNIT('name', 'Taxi Data: Enriching');

validatedData := Taxi.Files.Validation.inFile;

Holidays := Taxi.Util.HolidayDates;
holidaySet := SET(Holidays, holiday);

NYC_EAST_BOUND := -71.777491;
NYC_WEST_BOUND := -79.762590;
NYC_NORTH_BOUND := 45.015865;
NYC_SOUTH_BOUND := 40.477399;

Taxi.Files.Enriched.YellowLayout MakeEnrichedRec(Taxi.Files.Validation.YellowLayout inRec) := TRANSFORM
    SELF.pickup_date := Std.Date.FromStringToDate(inRec.tpep_pickup_datetime[..10], '%Y-%m-%d');
    SELF.pickup_time := Std.Date.FromStringToTime(inRec.tpep_pickup_datetime[12..], '%H:%M:%S');
    SELF.pickup_minutes_after_midnight := Std.Date.Hour(SELF.pickup_time) * 60 + Std.Date.Minute(SELF.pickup_time);
    SELF.pickup_time_window := SELF.pickup_minutes_after_midnight DIV 15 + 1; //15 could be replaced w/ a constant
    SELF.pickup_time_hour := Std.Date.Hour(SELF.pickup_time);
    SELF.pickup_day_of_week := Std.Date.DayOfWeek(SELF.pickup_date);
    SELF.dropoff_date := Std.Date.FromStringToDate(inRec.tpep_dropoff_datetime[..10], '%Y-%m-%d');
    SELF.dropoff_time := Std.Date.FromStringToTime(inRec.tpep_dropoff_datetime[12..], '%H:%M:%S');
    SELF.dropoff_minutes_after_midnight := Std.Date.Hour(SELF.dropoff_time) * 60 + Std.Date.Minute(SELF.dropoff_time);
    SELF.dropoff_time_window := SELF.dropoff_minutes_after_midnight DIV 15 + 1;
    SELF.dropoff_time_hour := Std.Date.Hour(SELF.dropoff_time);
    SELF.dropoff_day_of_week := Std.Date.DayOfWeek(SELF.dropoff_date);
    SELF.trip_duration_minutes := MAP
         (
            SELF.dropoff_date = SELF.pickup_date        =>  SELF.dropoff_minutes_after_midnight - SELF.pickup_minutes_after_midnight + 1,
            SELF.dropoff_date = SELF.pickup_date + 1    =>  SELF.dropoff_minutes_after_midnight + ((24 * 60) - SELF.pickup_minutes_after_midnight) + 1,
            SELF.dropoff_date > SELF.pickup_date + 1    =>  ((Std.Date.DaysBetween(SELF.pickup_date, SELF.dropoff_date) - 1) * (60 * 24)) + SELF.dropoff_minutes_after_midnight + ((24 * 60) - SELF.pickup_minutes_after_midnight) + 1,
            0
        );
    SELF.is_holiday := SELF.pickup_date IN holidaySet;
    SELF.is_good_passenger_count := inRec.passenger_count > 0;
    SELF.is_valid_vendor_id := inRec.VendorID IN [1,2];
    SELF.is_reasonable_distance := inRec.trip_distance > 0
                             AND inRec.trip_distance < 10000; //Change this
    SELF.total_adds_up := inRec.fare_amount + inRec.extra + inRec.mta_tax + inRec.tip_amount + inRec.tolls_amount + inRec.improvement_surcharge = inRec.total_amount;
    SELF.is_valid_rate_code_id := inRec.rate_code_id BETWEEN 1 AND 6;
    SELF.is_valid_payment_type := inRec.payment_type BETWEEN 1 AND 6;
    SELF.is_dropoff_after_pickup := inRec.tpep_dropoff_datetime >= inRec.tpep_pickup_datetime;
    SELF.is_zero_time_and_distance := (inRec.tpep_dropoff_datetime = inRec.tpep_pickup_datetime) AND (inRec.trip_distance = 0);
    SELF.is_ride_free := inRec.payment_type = 3 AND inRec.total_amount = 0;
    SELF.pickup_in_bounding_box := ( inRec.pickup_latitude BETWEEN NYC_SOUTH_BOUND AND NYC_NORTH_BOUND ) 
                                    AND ( inRec.pickup_longitude BETWEEN NYC_WEST_BOUND AND NYC_EAST_BOUND );
    SELF.dropoff_in_bounding_box := ( inRec.dropoff_latitude BETWEEN NYC_SOUTH_BOUND AND NYC_NORTH_BOUND ) 
                                    AND ( inRec.dropoff_longitude BETWEEN NYC_WEST_BOUND AND NYC_EAST_BOUND );
    SELF.is_valid_record := SELF.is_good_passenger_count
                              AND SELF.is_valid_vendor_id
                              AND SELF.is_reasonable_distance
                              AND SELF.total_adds_up
                              AND SELF.is_valid_rate_code_id
                              AND SELF.is_valid_payment_type
                              AND SELF.is_dropoff_after_pickup
                              AND SELF.is_zero_time_and_distance
                              AND SELF.is_ride_free
                              AND SELF.pickup_in_bounding_box
                              AND SELF.dropoff_in_bounding_box;
                              
    SELF := inRec;
END;

EnrichedData := PROJECT
    (
        validatedData,
        MakeEnrichedRec(LEFT)
    );

OUTPUT(EnrichedData);
//OUTPUT(validatedData, NAMED('validatedData'));
//OUTPUT(validatedData(total_adds_up), NAMED('invalidDistance'));
//OUTPUT(validatedData,, Taxi.Files.Validation.PATH, COMPRESSED, OVERWRITE);