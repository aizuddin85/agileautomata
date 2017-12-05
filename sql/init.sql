
--
-- Table structure for table `queue`
--

DROP TABLE IF EXISTS `queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `queue` (
  `id` mediumint(9) NOT NULL AUTO_INCREMENT,
  `sm9id` varchar(255) NOT NULL,
  `sm9info` varchar(255) NOT NULL,
  `hostname` varchar(255) DEFAULT NULL,
  `loglocation` varchar(255) DEFAULT NULL,
  `status` int(2) DEFAULT NULL,
  `jobtime` varchar(255) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user` varchar(255) NOT NULL,
  `sm9ag` varchar(255) NOT NULL,
  `middlewarestat` int(11) DEFAULT NULL,
  `submitby` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sm9id` (`sm9id`)
) ENGINE=InnoDB AUTO_INCREMENT=185 DEFAULT CHARSET=latin1;

