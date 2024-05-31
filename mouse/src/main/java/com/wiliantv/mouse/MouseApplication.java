package com.wiliantv.mouse;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MouseApplication {

	public static void main(String[] args) {

		System.setProperty("java.awt.headless", "false");
		SpringApplication.run(MouseApplication.class, args);
	}

}
