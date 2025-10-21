# 🚀 AWS Production Deployment Guide

Complete instructions to deploy the College Exam Result Website 3-tier architecture on AWS us-east-2.

---

## Overview

- Network infrastructure setup (VPC, subnets, NAT, IGW)
- Database Tier (RDS MySQL Multi-AZ)
- Application Tier (Flask API Servers in private subnet)
- Web Tier (NGINX Servers in public subnet)
- Load Balancers (External + Internal ALB)
- Auto Scaling Groups setup
- Domain and SSL handling with Route 53 & ACM

---

## Step 1: VPC and Network Setup

Follow `infrastructure/vpc-setup.md`.

## Step 2: Deploy Database

Create RDS instance with `infrastructure/rds-config.json`.

## Step 3: Deploy Application Servers

Launch EC2 with Flask app, security groups, and auto scaling.

## Step 4: Deploy Web Servers

Launch EC2 with NGINX frontend, connect to internal ALB.

## Step 5: Load Balancers

Configure external ALB for web tier, internal ALB for app tier.

## Step 6: Auto Scaling

Set CPU-based scaling for web and app tier ASGs.

## Step 7: Domain Setup & SSL

Use Route 53 for DNS; AWS ACM for SSL certificates.

---

_Last updated: October 2025_
