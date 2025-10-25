***README – SWE645 Assignment 1***

Author: Lavanesh Mahendran
Course: SWE645
Assignment: Homework 1
Date: September 12, 2025

***Project URLs***

S3 Hosted Website: http://swe-hw1-bucket.s3-website-us-east-1.amazonaws.com

EC2 Hosted Website: http://ec2-3-216-95-4.compute-1.amazonaws.com

***Project Contents***

1)index.html → Homepage (image, paragraph, link to survey page)

2)survey.html → Student Survey Form (textboxes, checkboxes, radios, dropdown, raffle, comments, buttons)

3)images/ → Folder containing images:

4)happy-student-boy-with-books-isolated-free-photo.jpg → About Me

5)images.jpg → Projects

6)pro.png → Skills

7)README.md → This file

***Deployment Steps***
 ***S3 Deployment***

1)Create an S3 bucket → Uncheck “Block all public access”.

2)Upload index.html, survey.html, error.html, and the images/ folder.

3)Enable Static Website Hosting → Index: index.html, Error: error.html.

3)Add bucket policy to allow public read access.

***Test site:***
   http://swe-hw1-bucket.s3-website-us-east-1.amazonaws.com

***EC2 Deployment***

1)Launch an EC2 instance (Amazon Linux) → Connect via SSH:

     ssh -i my-key.pem ec2-user@ec2-3-216-95-4.compute-1.amazonaws.com

2)Install a web server:

 sudo yum update -y
 sudo yum install -y httpd
 sudo systemctl start httpd
 sudo systemctl enable httpd


    ***Copy files to the server:***

1)scp -i my-key.pem index.html survey.html error.html -r images/ ec2-user@ec2-3-216-95-4.compute-1.amazonaws.com:/var/www/html/
    

     ***Test site:***
http://ec2-3-216-95-4.compute-1.amazonaws.com