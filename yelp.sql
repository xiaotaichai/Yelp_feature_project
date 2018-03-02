## create table and inseart data
psql -f yelp_pg.no_insert.sql yelp_xchai
psql -f yelp_pg.insert_ub.sql2 yelp_xchai
psql -f yelp_pg.insert_noub.sql2 yelp_xchai


## clean table and drop useless columns.
ALTER TABLE business DROP COLUMN stars RESTRICT;
ALTER TABLE business DROP COLUMN review_count RESTRICT;
ALTER TABLE business DROP COLUMN is_open RESTRICT;

## create a business_full table with category
CREATE TABLE  business_full AS
SELECT b.id, b.name, b.address, b.city, b.state, b.postal_code, b.latitude, b.longitude, c.category
FROM business b LEFT JOIN category c ON b.id = c.business_id;



## create distance function to calculate the approximate distance between coordinates
## This function only gives distance
CREATE OR REPLACE FUNCTION John_Chinese_BBQ(_category char)
	RETURNS TABLE (id char, name char, distance double precision) AS
$func$
DECLARE
	latitude double precision;
	longitude double precision;

BEGIN

FOR latitude, longitude IN 
	SELECT a.latitude, a.longitude
	FROM   business_full a
	WHERE  a.category = _category
LOOP
	distance := sqrt((latitude - 43.8409)^2 + (longitude + 79.3996)^2);
	RETURN NEXT;

END LOOP;
END
$func$ LANGUAGE plpgsql STABLE;
  

## This query works to find the doctors nearest to John’s Chinese BBQ Restaurant in order of increasing
## But i want to write a nice function.
select name, latitude, longitude, sqrt((latitude - 43.8409)^2 + (longitude + 79.3996)^2)
as distance from business_full where category = 'Doctors'
ORDER by distance;


## Add the distance column to the business_full table.
ALTER TABLE business_full ADD COLUMN distance double precision;

## This function is the one that works well.
CREATE OR REPLACE FUNCTION distance_John_Chinese_BBQ(_category char)
	RETURNS SETOF business_full AS
$$
	SELECT id, name, address, city, state, postal_code,latitude, longitude, category, sqrt((latitude - 43.8409)^2 + (longitude + 79.3996)^2)
as distance
	FROM   business_full 
	WHERE  category = _category
	ORDER BY distance

$$ LANGUAGE 'sql';



## Function for listing different types of businesses nearest to Healing Hands Esthetics.
CREATE OR REPLACE FUNCTION healing_hands_esthetics(_category char)
RETURNS SETOF business_full AS
$$
	SELECT id, name, address, city, state, postal_code,latitude, longitude, category, 
	sqrt((latitude - 35.9791)^2 + (longitude + 114.83)^2) as distance
	FROM   business_full 
	WHERE  category = _category
	ORDER BY distance

$$ LANGUAGE 'sql';




-- select id, name, address, city, state, postal_code,latitude, longitude, category, 
-- sqrt((latitude - (select latitude from business where id = '--6MefnULPED_I942VcFNA'))^2 + 
-- 	(longitude - (SELECT longitude from business where id = '--6MefnULPED_I942VcFNA'))^2)
-- as distance 
-- from business_full where category = 'Doctors'
-- ORDER by distance;


## The function doesn't require you to adjust longitude and latitude for the given business mannually every time you want to 
## look for an different business. You only need to pass the business id of the business you are and the type of business you 
## are looking for. For example, to look for the doctors nearest to John's Chinese BBQ Restaurant, you put in the business id 
## of John's Chinese BBQ Restaurant and 'Doctors' as the category.
CREATE OR REPLACE FUNCTION feature(_id char, _category char)
RETURNS SETOF business_full AS
$$
	SELECT id, name, address, city, state, postal_code,latitude, longitude, category, 
	sqrt((latitude - (select latitude from business_full where id = _id))^2 + (longitude - (select longitude from business_full where id = _id))^2) as distance
	FROM   business_full 
	WHERE  category = _category
	ORDER BY distance

$$ LANGUAGE 'sql';



select feature('--6MefnULPED_I942VcFNA', 'Doctors') limit 5;
