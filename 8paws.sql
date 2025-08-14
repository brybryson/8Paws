-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 14, 2025 at 12:33 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `8paws`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `LinkCustomerToUser` (IN `p_user_id` INT, IN `p_phone` VARCHAR(20))   BEGIN
    DECLARE customer_exists INT DEFAULT 0;
    
    -- Check if customer exists with this phone
    SELECT COUNT(*) INTO customer_exists 
    FROM customers 
    WHERE phone = p_phone AND user_id IS NULL;
    
    IF customer_exists > 0 THEN
        -- Update customer record to link with user
        UPDATE customers 
        SET user_id = p_user_id, 
            created_via = 'online',
            updated_at = NOW()
        WHERE phone = p_phone AND user_id IS NULL;
        
        -- Link all pets of this customer to the user
        INSERT INTO user_pets (user_id, pet_id, is_primary_owner)
        SELECT p_user_id, p.id, TRUE
        FROM pets p
        JOIN customers c ON p.customer_id = c.id
        WHERE c.phone = p_phone AND c.user_id = p_user_id;
        
        -- Link all bookings to the user
        UPDATE bookings b
        JOIN pets p ON b.pet_id = p.id
        JOIN customers c ON p.customer_id = c.id
        SET b.user_id = p_user_id, 
            b.booking_type = 'online',
            b.updated_at = NOW()
        WHERE c.user_id = p_user_id AND b.user_id IS NULL;
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `GetUserActiveBookingsCount` (`p_user_id` INT) RETURNS INT(11) DETERMINISTIC READS SQL DATA BEGIN
    DECLARE booking_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO booking_count
    FROM bookings b
    WHERE b.user_id = p_user_id 
    AND b.status NOT IN ('completed', 'cancelled');
    
    RETURN booking_count;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `pet_id` int(11) NOT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` time NOT NULL,
  `estimated_duration` int(11) DEFAULT 120,
  `status` enum('scheduled','confirmed','in_progress','completed','cancelled','no_show') DEFAULT 'scheduled',
  `total_amount` decimal(10,2) DEFAULT 0.00,
  `special_instructions` text DEFAULT NULL,
  `staff_notes` text DEFAULT NULL,
  `reminder_sent` tinyint(1) DEFAULT 0,
  `confirmation_sent` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `appointment_services`
--

CREATE TABLE `appointment_services` (
  `id` int(11) NOT NULL,
  `appointment_id` int(11) NOT NULL,
  `service_id` int(11) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `pet_id` int(11) NOT NULL,
  `rfid_tag_id` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `status` enum('checked-in','bathing','grooming','ready','completed','cancelled') DEFAULT 'checked-in',
  `check_in_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `estimated_completion` timestamp NULL DEFAULT NULL,
  `actual_completion` timestamp NULL DEFAULT NULL,
  `staff_notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `user_id` int(11) DEFAULT NULL,
  `booking_type` enum('walk_in','online') DEFAULT 'walk_in'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `pet_id`, `rfid_tag_id`, `total_amount`, `status`, `check_in_time`, `estimated_completion`, `actual_completion`, `staff_notes`, `created_at`, `updated_at`, `user_id`, `booking_type`) VALUES
(1, 1, 1, 300.00, 'checked-in', '2025-08-14 07:22:33', '2025-08-14 09:22:33', NULL, NULL, '2025-08-14 07:22:33', '2025-08-14 07:22:33', NULL, 'walk_in'),
(2, 2, 2, 600.00, 'checked-in', '2025-08-14 09:24:50', '2025-08-14 11:24:50', NULL, NULL, '2025-08-14 09:24:50', '2025-08-14 09:24:50', NULL, 'walk_in'),
(3, 3, 3, 300.00, 'checked-in', '2025-08-14 09:56:13', '2025-08-14 11:56:13', NULL, NULL, '2025-08-14 09:56:13', '2025-08-14 09:56:13', NULL, 'walk_in');

-- --------------------------------------------------------

--
-- Table structure for table `booking_services`
--

CREATE TABLE `booking_services` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `service_id` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `booking_services`
--

INSERT INTO `booking_services` (`id`, `booking_id`, `service_id`, `price`) VALUES
(1, 1, 1, 300.00),
(2, 2, 4, 600.00),
(3, 3, 1, 300.00);

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `emergency_contact` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `user_id` int(11) DEFAULT NULL,
  `created_via` enum('walk_in','online') DEFAULT 'walk_in'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `name`, `phone`, `email`, `address`, `emergency_contact`, `created_at`, `updated_at`, `user_id`, `created_via`) VALUES
(1, 'TEst', '0912-344-3434', 'mewtwo@gmail.com', NULL, NULL, '2025-08-14 07:22:33', '2025-08-14 07:22:33', NULL, 'walk_in'),
(2, 'Test', '0969-121-2725', 'ivyrivera50@gmail.com', NULL, NULL, '2025-08-14 09:24:50', '2025-08-14 09:24:50', NULL, 'walk_in');

-- --------------------------------------------------------

--
-- Table structure for table `login_attempts`
--

CREATE TABLE `login_attempts` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` text DEFAULT NULL,
  `successful` tinyint(1) NOT NULL,
  `attempted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` enum('email','sms','push') NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `status` enum('pending','sent','failed','read') DEFAULT 'pending',
  `sent_at` timestamp NULL DEFAULT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `related_booking_id` int(11) DEFAULT NULL,
  `related_appointment_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pets`
--

CREATE TABLE `pets` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `breed` varchar(255) NOT NULL,
  `age_range` enum('puppy','young','adult','senior') DEFAULT NULL,
  `size` enum('small','medium','large','xlarge') DEFAULT NULL,
  `special_notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pets`
--

INSERT INTO `pets` (`id`, `customer_id`, `name`, `breed`, `age_range`, `size`, `special_notes`, `created_at`, `updated_at`) VALUES
(1, 1, 'Buddy', 'Golden Retriever', 'puppy', 'medium', '', '2025-08-14 07:22:33', '2025-08-14 07:22:33'),
(2, 2, 'Buddy', 'Golden Retriever', 'puppy', 'medium', '', '2025-08-14 09:24:50', '2025-08-14 09:24:50'),
(3, 2, 'Buddy', 'Golden Retriever', 'puppy', 'medium', '', '2025-08-14 09:56:13', '2025-08-14 09:56:13');

-- --------------------------------------------------------

--
-- Table structure for table `rfid_tags`
--

CREATE TABLE `rfid_tags` (
  `id` int(11) NOT NULL,
  `tag_id` varchar(20) NOT NULL,
  `pet_id` int(11) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `assigned_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rfid_tags`
--

INSERT INTO `rfid_tags` (`id`, `tag_id`, `pet_id`, `is_active`, `assigned_at`, `created_at`) VALUES
(1, 'A1B2C3D4', 1, 1, '2025-08-14 07:22:33', '2025-08-14 07:04:54'),
(2, 'B2C3D4E5', 2, 1, '2025-08-14 09:24:50', '2025-08-14 07:04:54'),
(3, 'C3D4E5F6', 3, 1, '2025-08-14 09:56:13', '2025-08-14 07:04:54'),
(4, 'D4E5F6G7', NULL, 1, NULL, '2025-08-14 07:04:54'),
(5, 'E5F6G7H8', NULL, 1, NULL, '2025-08-14 07:04:54'),
(6, 'F6G7H8I9', NULL, 1, NULL, '2025-08-14 07:04:54'),
(7, 'G7H8I9J0', NULL, 1, NULL, '2025-08-14 07:04:54'),
(8, 'H8I9J0K1', NULL, 1, NULL, '2025-08-14 07:04:54'),
(9, 'I9J0K1L2', NULL, 1, NULL, '2025-08-14 07:04:54'),
(10, 'J0K1L2M3', NULL, 1, NULL, '2025-08-14 07:04:54');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `category` enum('basic','premium','addon') NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`id`, `name`, `price`, `category`, `description`, `is_active`) VALUES
(1, 'Basic Bath', 300.00, 'basic', 'Shampoo, rinse, and basic dry', 1),
(2, 'Nail Trimming', 150.00, 'basic', 'Professional nail care', 1),
(3, 'Ear Cleaning', 200.00, 'basic', 'Safe ear cleaning and inspection', 1),
(4, 'Full Grooming Package', 600.00, 'premium', 'Bath, cut, style, nails, ears, and teeth', 1),
(5, 'Dental Care', 250.00, 'premium', 'Teeth cleaning and oral health check', 1),
(6, 'De-shedding Treatment', 400.00, 'premium', 'Reduces shedding up to 90%', 1),
(7, 'Nail Polish', 100.00, 'addon', 'Pet-safe nail colors', 1),
(8, 'Perfume & Bow', 150.00, 'addon', 'Finishing touches for a perfect look', 1);

-- --------------------------------------------------------

--
-- Table structure for table `status_updates`
--

CREATE TABLE `status_updates` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `status` enum('checked-in','bathing','grooming','ready','completed') NOT NULL,
  `notes` text DEFAULT NULL,
  `updated_by` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `status_updates`
--

INSERT INTO `status_updates` (`id`, `booking_id`, `status`, `notes`, `updated_by`, `created_at`) VALUES
(1, 1, 'checked-in', 'Pet checked in successfully', NULL, '2025-08-14 07:22:33'),
(2, 2, 'checked-in', 'Pet checked in successfully', NULL, '2025-08-14 09:24:50'),
(3, 3, 'checked-in', 'Pet checked in successfully', NULL, '2025-08-14 09:56:13');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `email_verified` tinyint(1) DEFAULT 0,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `verification_code` varchar(6) DEFAULT NULL,
  `verification_token` varchar(64) DEFAULT NULL,
  `verification_code_expires` timestamp NOT NULL DEFAULT (current_timestamp() + interval 30 minute),
  `password_reset_token` varchar(64) DEFAULT NULL,
  `password_reset_expires` timestamp NULL DEFAULT NULL,
  `marketing_emails` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `last_login` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `first_name`, `last_name`, `email`, `phone`, `password_hash`, `email_verified`, `email_verified_at`, `verification_code`, `verification_token`, `verification_code_expires`, `password_reset_token`, `password_reset_expires`, `marketing_emails`, `is_active`, `last_login`, `created_at`, `updated_at`) VALUES
(1, 'Admin', 'User', 'admin@8pawspetboutique.com', '0912-345-6789', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, '2025-08-14 08:47:58', NULL, NULL, '2025-08-14 09:17:58', NULL, NULL, 0, 1, NULL, '2025-08-14 08:47:58', '2025-08-14 08:47:58'),
(10, 'Test', 'Test', 'ivyrivera50@gmail.com', '0967-663-6689', '$2y$10$41Sly1tQvQqsCipqmNiis.59lukjTqJewI9a6cVQ2pKJOXBilv97i', 1, '2025-08-14 09:21:17', NULL, NULL, '2025-08-14 09:50:58', NULL, NULL, 1, 1, NULL, '2025-08-14 09:20:58', '2025-08-14 09:21:17');

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_dashboard_view`
-- (See below for the actual view)
--
CREATE TABLE `user_dashboard_view` (
`user_id` int(11)
,`first_name` varchar(100)
,`last_name` varchar(100)
,`email` varchar(255)
,`phone` varchar(20)
,`last_login` timestamp
,`total_pets` bigint(21)
,`active_bookings` bigint(21)
,`completed_bookings` bigint(21)
,`last_booking_date` timestamp
,`total_spent` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `user_pets`
--

CREATE TABLE `user_pets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `pet_id` int(11) NOT NULL,
  `is_primary_owner` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_preferences`
--

CREATE TABLE `user_preferences` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `preference_key` varchar(100) NOT NULL,
  `preference_value` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `session_token` varchar(128) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_activity` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure for view `user_dashboard_view`
--
DROP TABLE IF EXISTS `user_dashboard_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_dashboard_view`  AS SELECT `u`.`id` AS `user_id`, `u`.`first_name` AS `first_name`, `u`.`last_name` AS `last_name`, `u`.`email` AS `email`, `u`.`phone` AS `phone`, `u`.`last_login` AS `last_login`, count(distinct `up`.`pet_id`) AS `total_pets`, count(distinct case when `b`.`status` not in ('completed','cancelled') then `b`.`id` end) AS `active_bookings`, count(distinct case when `b`.`status` = 'completed' then `b`.`id` end) AS `completed_bookings`, max(`b`.`created_at`) AS `last_booking_date`, sum(case when `b`.`status` = 'completed' then `b`.`total_amount` else 0 end) AS `total_spent` FROM ((`users` `u` left join `user_pets` `up` on(`u`.`id` = `up`.`user_id`)) left join `bookings` `b` on(`u`.`id` = `b`.`user_id`)) GROUP BY `u`.`id`, `u`.`first_name`, `u`.`last_name`, `u`.`email`, `u`.`phone`, `u`.`last_login` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pet_id` (`pet_id`),
  ADD KEY `idx_appointment_date` (`appointment_date`),
  ADD KEY `idx_user_date` (`user_id`,`appointment_date`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `appointment_services`
--
ALTER TABLE `appointment_services`
  ADD PRIMARY KEY (`id`),
  ADD KEY `service_id` (`service_id`),
  ADD KEY `idx_appointment` (`appointment_id`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pet_id` (`pet_id`),
  ADD KEY `rfid_tag_id` (`rfid_tag_id`),
  ADD KEY `fk_bookings_users` (`user_id`);

--
-- Indexes for table `booking_services`
--
ALTER TABLE `booking_services`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `service_id` (`service_id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_customers_users` (`user_id`);

--
-- Indexes for table `login_attempts`
--
ALTER TABLE `login_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_email_ip` (`email`,`ip_address`),
  ADD KEY `idx_attempted_at` (`attempted_at`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `related_booking_id` (`related_booking_id`),
  ADD KEY `related_appointment_id` (`related_appointment_id`),
  ADD KEY `idx_user_status` (`user_id`,`status`),
  ADD KEY `idx_type_status` (`type`,`status`);

--
-- Indexes for table `pets`
--
ALTER TABLE `pets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `customer_id` (`customer_id`);

--
-- Indexes for table `rfid_tags`
--
ALTER TABLE `rfid_tags`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tag_id` (`tag_id`),
  ADD KEY `pet_id` (`pet_id`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `status_updates`
--
ALTER TABLE `status_updates`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_phone` (`phone`),
  ADD KEY `idx_verification_token` (`verification_token`),
  ADD KEY `idx_password_reset_token` (`password_reset_token`);

--
-- Indexes for table `user_pets`
--
ALTER TABLE `user_pets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_pet` (`user_id`,`pet_id`),
  ADD KEY `pet_id` (`pet_id`);

--
-- Indexes for table `user_preferences`
--
ALTER TABLE `user_preferences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_preference` (`user_id`,`preference_key`);

--
-- Indexes for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `session_token` (`session_token`),
  ADD KEY `idx_session_token` (`session_token`),
  ADD KEY `idx_user_expires` (`user_id`,`expires_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `appointment_services`
--
ALTER TABLE `appointment_services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `booking_services`
--
ALTER TABLE `booking_services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `login_attempts`
--
ALTER TABLE `login_attempts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pets`
--
ALTER TABLE `pets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `rfid_tags`
--
ALTER TABLE `rfid_tags`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `status_updates`
--
ALTER TABLE `status_updates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `user_pets`
--
ALTER TABLE `user_pets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_preferences`
--
ALTER TABLE `user_preferences`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `appointments_ibfk_2` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `appointment_services`
--
ALTER TABLE `appointment_services`
  ADD CONSTRAINT `appointment_services_ibfk_1` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `appointment_services_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`),
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`rfid_tag_id`) REFERENCES `rfid_tags` (`id`),
  ADD CONSTRAINT `fk_bookings_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `booking_services`
--
ALTER TABLE `booking_services`
  ADD CONSTRAINT `booking_services_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
  ADD CONSTRAINT `booking_services_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`);

--
-- Constraints for table `customers`
--
ALTER TABLE `customers`
  ADD CONSTRAINT `fk_customers_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`related_booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notifications_ibfk_3` FOREIGN KEY (`related_appointment_id`) REFERENCES `appointments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `pets`
--
ALTER TABLE `pets`
  ADD CONSTRAINT `pets_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`);

--
-- Constraints for table `rfid_tags`
--
ALTER TABLE `rfid_tags`
  ADD CONSTRAINT `rfid_tags_ibfk_1` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`);

--
-- Constraints for table `status_updates`
--
ALTER TABLE `status_updates`
  ADD CONSTRAINT `status_updates_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`);

--
-- Constraints for table `user_pets`
--
ALTER TABLE `user_pets`
  ADD CONSTRAINT `user_pets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_pets_ibfk_2` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_preferences`
--
ALTER TABLE `user_preferences`
  ADD CONSTRAINT `user_preferences_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `user_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
