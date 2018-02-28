SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
DROP DATABASE realestatedb;
CREATE DATABASE realestatedb;
USE realestatedb;
SET foreign_key_checks=0;

/* Dump Table Data */
/* I was made to revert to 2 floating point #'s instead of a POINT to represent lat/long. I had to make this change
   because POINT's are not compatable for foreign key constraints (due to their underlying structure being
   built as a 'blob'), thus were not a valid connector for the three tables
   'residence', 'notablesurroundingareas', and 'locationinformation'. This inhibited my ability to create complex stored
   procedures involving the tables 'notablesurroundingareas' and 'locationinformation' */
CREATE TABLE IF NOT EXISTS `agent` (
  `agent_id` int(5) NOT NULL DEFAULT 0,
  `agent_fname` varchar(20) DEFAULT '',
  `agent_lname` varchar(20) DEFAULT '',
  `agent_phone` int(10) DEFAULT 0,
  PRIMARY KEY (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `client` (
  `client_id` int(5) NOT NULL DEFAULT 0,
  `c_client_fname` varchar(20) DEFAULT '',
  `c_client_lname` varchar(20) DEFAULT '',
  `c_client_phone` int(10) DEFAULT 0,
  `c_client_email` varchar(30) DEFAULT '',
  PRIMARY KEY (`client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `locationinformation` (
  `latitude` float(10,6),
  `longitude` float(10,6),
  `li_city` varchar(30) DEFAULT '',
  `li_zip_code` int(5) DEFAULT 0,
  `li_area_code` int(3) DEFAULT 0,
  PRIMARY KEY (`latitude`,`longitude`) 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `residence` (
  `res_id` int(5) NOT NULL DEFAULT 0,
  `latitude` float(10,6),
  `longitude` float(10,6),
  `res_construction_date` datetime DEFAULT NULL,
  `res_gross_living_area` int(10) DEFAULT 0,
  `res_land_acreage` varchar(4) DEFAULT '0',
  `res_non_gla_sqft` int(10) DEFAULT 0,
  `res_street_name` varchar(30) DEFAULT '',
  `res_house_number` int(10) DEFAULT 0,
  PRIMARY KEY (`res_id`),
  FOREIGN KEY (`latitude`,`longitude`)
  REFERENCES locationinformation(`latitude`,`longitude`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `notablesurroundingareas` (
  `nsa_id` int(5) NOT NULL DEFAULT 0,
  `latitude` float(10,6),
  `longitude` float(10,6),
  `nsa_location_type` varchar(20) DEFAULT '',
  `nsa_location_name` varchar(30) DEFAULT '',
  PRIMARY KEY (`nsa_id`),
  FOREIGN KEY (`latitude`,`longitude`)
  REFERENCES locationinformation(`latitude`,`longitude`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `propertyclass` (
  `res_id` int(5) NOT NULL DEFAULT 0,
  `pc_property_type` varchar(30) DEFAULT '',
  `pc_max_occupancy_count` int(5) DEFAULT 0,
  FOREIGN KEY (`res_id`)
  REFERENCES residence(`res_id`)
  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `propertyforsale` (
  `res_id` int(5) NOT NULL DEFAULT 0,
  `agent_id` int(5) NOT NULL DEFAULT 0,
  `pfs_appraisal_value` int(20) DEFAULT 0,
  `pfs_previous_value` int(20) DEFAULT 0,
  `pfs_market_price` int(20) DEFAULT 0,
  FOREIGN KEY (`res_id`)
  REFERENCES residence(`res_id`)
  ON DELETE CASCADE,
  FOREIGN KEY (`agent_id`)
  REFERENCES agent(`agent_id`)
  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `sales` (
  `client_id` int(5) NOT NULL DEFAULT 0,
  `agent_id` int(5) NOT NULL DEFAULT 0,
  `res_id` int(5) NOT NULL DEFAULT 0,
  `s_dateofsale` datetime DEFAULT NULL,
  `s_saleValue`  int(20) DEFAULT 0,
  FOREIGN KEY (`client_id`)
  REFERENCES `client`(`client_id`)
  ON DELETE CASCADE,
  FOREIGN KEY (`res_id`)
  REFERENCES residence(`res_id`)
  ON DELETE CASCADE,
  FOREIGN KEY (`agent_id`)
  REFERENCES agent(`agent_id`)
  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `clientlist` (
  `agent_id` int(5) NOT NULL DEFAULT 0,
  `client_id` int(5) NOT NULL DEFAULT 0,
  `cl_clientincome` int(10) DEFAULT 0,
  `cl_subscription` boolean DEFAULT false,
  FOREIGN KEY (`client_id`)
  REFERENCES `client`(`client_id`)
  ON DELETE CASCADE,
  FOREIGN KEY (`agent_id`)
  REFERENCES agent(`agent_id`)
  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `showing` (
  `res_id` int(5) NOT NULL DEFAULT 0,
  `agent_id` int(5) NOT NULL DEFAULT 0,
  `show_showingDatetime` datetime DEFAULT NULL,
  FOREIGN KEY (`agent_id`)
  REFERENCES agent(`agent_id`)
  ON DELETE CASCADE,
  FOREIGN KEY (`res_id`)
  REFERENCES residence(`res_id`)
  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/* table data dump complete */

/* dump view data */
/* View (1/3) Agent List 
	Justification: an updated view of all current agents */
CREATE VIEW agentList AS 
SELECT CONCAT(agent_fname,' ',agent_lname) AS name, agent_phone
FROM `agent`;
/* View (2/3) TownHouse List 
	Justification: a list of townhomes in a given area */
CREATE VIEW townhomeList AS
SELECT res_id, pc_property_type
FROM `propertyclass`
WHERE pc_property_type in ("townhome");
/* View (3/3) Recent sales List
	Justification: a list of homes sold within the last year */
CREATE VIEW recentsalesList AS
SELECT res_id
FROM `sales`
WHERE s_dateofsale > '2017-12-00 00:00:00';
/* view data dump complete */

/* dump stored procedure data */
/* I wanted to have stored procedures for NSA's within a distance, but I was unable to do this due to the fact that
   I was made to revert to 2 floating point #'s instead of a POINT to represent lat/long. I had to make this change
   because POINT's are not compatable for foreign key constraints, thus were not a valid connector for the three tables
   'residence', 'notablesurroundingareas', and 'locationinformation'. This inhibited my ability to create complex stored
   procedures involving the tables 'notablesurroundingareas' and 'locationinformation' */
/* Stored Procedure (1/10) Query Creator
	Justification: Standard procedure to output the name and date of the query creator */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `QueryCreator`(Cname varchar(30))
BEGIN
    SELECT CONCAT('ran by ',Cname,' on ', now());
END$$
DELIMITER ;
/* Stored Procedure (2/10) getSaleHistory
	Justification: Get the recorded history of sales for a given residence id */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getSaleHistory`( res_idX INT(5) )
BEGIN
    SELECT s.res_id AS `residence`, s.s_dateofsale AS `sale date`
    FROM sales s
    WHERE s.res_id = res_idX;
END$$
DELIMITER ;
/* Stored Procedure (3/10) getResidenceAreaInformation
	Justification: Get information about the area a particular residence is in */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getResidenceAreaInformaton`( res_idX INT(5) )
BEGIN
    SELECT l.li_city AS `City`, l.li_zip_code AS `Zip Code`, l.li_area_code AS `Area Code`
    FROM locationinformation l JOIN residence r ON l.res_id = r.res_id
    WHERE r.res_id = res_idX;
END$$
DELIMITER ;
/* Stored Procedure (4/10) getAgentClientCount
	Justificaion: Generate a list containing the clientele number of a given agent */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getClientCount`( agent_idX INT(5) )
BEGIN
    SELECT COUNT(agent_idX) AS `Client Count`
    FROM clientlist c
    WHERE c.agent_id = agent_idX;
END$$
DELIMITER ;
/* Stored Procedure (5/10) getAgentRecentSales
	Justification: Get the total amount of value sold by a given agent in the last year */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAgentRecentSales`( agent_idX INT(5) )
BEGIN
    SELECT SUM(s.s_saleValue) AS `Total Sales Value`, CONCAT(a.agent_fname,' ',a.agent_lname) as `Agent`
    FROM sales s JOIN agent a ON s.agent_id = a.agent_id
    WHERE (s.agent_id = agent_idX) AND (s.s_dateofsale > '2017-12-00 00:00:00');
END$$
DELIMITER ;
/* Stored Procedure (6/10) getShowings
	Justification: Get a list of all showings within a given timeframe */ 
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getShowings`( time1 datetime, time2 datetime )
BEGIN
    SELECT s.res_id AS `residence`, s.show_showingDatetime AS `Showing Datetime`, 
    CONCAT(a.agent_fname,' ',a.agent_lname) AS `Agent`, a.agent_phone AS `Agent Contact`
    FROM showing s JOIN agent a on s.agent_id = a.agent_id
    WHERE (s.show_showingDatetime >= time1) AND (s.show_showingDatetime <= time2);
END$$
DELIMITER ;
/* Stored Procedure (7/10) getApartmentsForSale
	Justification: Generate a list of apartments for sale in a given price range */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getApartmentsForSale`( price1 int(10), price2 int(10) )
BEGIN
    SELECT r.res_id AS `Residence`, r.res_gross_living_area AS `GLA`, p.pc_property_type AS `Property Type`,
    x.pfs_appraisal_value AS `Appraisal Value`, x.pfs_market_price AS `Market Price`
    FROM propertyclass p JOIN residence r ON p.res_id = r.res_id JOIN propertyforsale x on x.res_id = r.res_id
    WHERE (x.pfs_market_price >= price1) AND (x.pfs_market_price <= price2);
END$$
DELIMITER ;
/* Stored Procedure (8/10) getApartmentsInCity
	Justification: Generate a list of apartments for sale in a given city */
/* Due to the structural change of lat/long system, this query had to be made differently */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getApartmentsInCity`( cityName varchar(30) )
BEGIN
    SELECT r.res_id AS `Residence`, r.res_gross_living_area AS `GLA`, p.pc_property_type AS `Property Type`,
	x.pfs_market_price AS `Market Price`, l.li_city AS `City`
    FROM propertyclass p JOIN residence r ON p.res_id = r.res_id JOIN propertyforsale x on x.res_id = r.res_id
    JOIN locationinformation l ON r.latitude = l.latitude
    WHERE (r.latitude = l.latitude) AND (r.longitude = l.longitude) AND (l.li_city in (cityName));
END$$
DELIMITER ;
/* Stored Procedure (9/10) getClientInformation
	Justification: retrieve information about a given client */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getClientInformation`( client_idX int(5) )
BEGIN
    SELECT CONCAT(c.c_client_fname,' ',c.c_client_lname) AS `Client Name`, COUNT(s.client_id) AS `Residences Bought`,
    x.agent_id AS `Client's Agent`
    FROM `client` c JOIN clientlist x ON c.client_id = x.client_id JOIN sales s on s.client_id = c.client_id
    WHERE c.client_id = client_idX;
END$$
DELIMITER ;
/* Stored Procedure (10/10) getLargeHomes
	Justification: generate a lost of homes for sale that have an acreage between 2 given values */
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getLargeHomes`( minimum varchar(4), maximum varchar(4) )
BEGIN
    SELECT r.res_id AS `Residence`, p.pc_property_type AS `Property Type`, x.pfs_market_price AS `Property Price`
    FROM residence r JOIN propertyclass p on r.res_id = p.res_id JOIN propertyforsale x ON r.res_id = x.res_id
    WHERE (r.res_land_acreage >= minimum) AND (r.res_land_acreage <= maximum);
END$$
DELIMITER ;
/* Stored Procedure data dump complete */

/* Dump Trigger data */
/* Trigger (1/3) locationinformation_check
	Justification: Check all entries into locationinformation for valid lat/long coordinates */
DELIMITER $$
CREATE TRIGGER locationinformation_check
BEFORE UPDATE ON `locationinformation`
FOR EACH ROW
BEGIN 
  IF NEW.latitude < 0 THEN SET NEW.latitude = 0;
  ELSEIF NEW.latitude > 90 THEN SET NEW.latitude = 90;
  end if;
  IF NEW.longitude < 0 THEN SET NEW.longitude = 0;
  ELSEIF NEW.longitude > 180 THEN SET NEW.longitude = 180;
  end if;
END$$
DELIMITER ;
/* Trigger (2/3) pfs_check
	Justification: verify that all updates to pfs have valid values */
DELIMITER $$
CREATE TRIGGER pfs_check
BEFORE UPDATE ON `propertyforsale`
FOR EACH ROW
BEGIN 
  IF NEW.pfs_appraisal_value < 0 THEN SET NEW.pfs_appraisal_value = 0;
  END IF;
  IF NEW.pfs_previous_vaue < 0 THEN SET NEW.pfs_previous_vaue = 0;
  END IF;
  IF NEW.pfs_market_price < 0 THEN SET NEW.pfs_market_price = 0;
  END IF;
END$$
DELIMITER ;
/* Trigger (3/3) showing_check
	Justification: Verify that entered showing dates are valid */
DELIMITER $$
CREATE TRIGGER showing_check
BEFORE UPDATE ON `showing`
FOR EACH ROW
BEGIN 
  IF NEW.show_showingDatetime < NOW() THEN SET NEW.show_showingDatetime = NULL;
  END IF;
END$$
DELIMITER ;
/* Trigger data dump complete */



