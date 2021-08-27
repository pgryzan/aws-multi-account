////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Author:         Patrick L. Gryzan
//  Repo:           aws-multi-account
//  File:           variables.tf
//  Date:           August 2021
//  Description:    terraform variables
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//  Project Information
variable "project" {
    type = map
}

//  AWS Information
variable "aws" {
    type = map
}

//  VPC Information
variable "vpc" {
    type = map
}