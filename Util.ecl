IMPORT Std;

EXPORT Util := MODULE

    EXPORT BurroughsBoundingBoxes := DATASET
       (
           [
               {1, 'Queens', 40.750111, -73.993896, 40.750111, -73.993896, 40.750111, -73.993896, 40.750111, -73.993896},
               {2, 'Long Island', 40.750111, -73.993896, 40.750111, -73.993896, 40.750111, -73.993896, 40.750111, -73.993896}
           ],
           {
               UNSIGNED1   id;
               STRING      burroughs_name;
               DECIMAL9_6  nw_lat;
               DECIMAL9_6  nw_lon;
               DECIMAL9_6  sw_lat;
               DECIMAL9_6  sw_lon;
               DECIMAL9_6  ne_lat;
               DECIMAL9_6  ne_lon;
               DECIMAL9_6  se_lat;
               DECIMAL9_6  se_lon;
           }
       );

    EXPORT HolidayDates := DATASET
       (
           [
               {20150101},
               {20150119},
               {20150216},
               {20150525},
               {20150703},
               {20150907},
               {20151012},
               {20151111},
               {20151126},
               {20151225},
               {20160101},
               {20160118},
               {20160215},
               {20160530}
            ],
           {Std.Date.Date_t holiday}

       );
END;