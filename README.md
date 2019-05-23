# ERGO CRM/Omnichannel: Kubernetes Setup

This repo contains everything you need to get up and running with your own Kubernetes cluster on AWS. It also contains shared architectural base components, which are not part of a dedicated microservice repository.

## Contents 

- [Documentation](docs)
- [Setup Scripts](scripts)
- [Open Issues/Checklist](open-issues.md)
- [Ansible Deployment Scripts](deployment)


## Getting started

Before you can start the cluster setup, there are a few things you need in advance:

1. **Amazon Web Services (AWS) account** for the ITERGO organization  
   This can be obtained by [mailing the Cloud Competence Center(CCC)](mailto:cloud@itergo.com). You will receive a mail with the following information:

    ```
    User name:       <your ERGO personnel number>
    Password:        xxxxxxxxxxxx
    
    Account:         ergo-aws-0000
    Role:            engineer

    User Account ID: 000000000000 
    Role Account ID: 000000000000
    ```

    > **Note:** The [Role Account ID](https://console.aws.amazon.com/iam/home?region=eu-central-1#/roles/engineer) can also be determined on AWS.  
    > For the [User Account ID](https://console.aws.amazon.com/iam/home?region=eu-west-1#/users), select your user name from the list.

    Login with your user name and password: https://itergo.signin.aws.amazon.com/console.

    To be able to log in via the command line in the future, you need to create your security credentials once:

    1. Open the [IAM console](https://console.aws.amazon.com/iam/home#/users) and select your user name.
    
    2. Choose the **Security Credentials** tab, then choose **Create Access Key**. Your credentials will look something like this:

        > Access Key ID: AKIAIOSFODNN7EXAMPLE
        > Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

        Your credentials will be only shown **once**, so better download the CSV for further reference. Keep it confidential in order to protect your account.
   
2. **Account for ITERGO's Docker registry** (`hub.itgo-devops.org`)  
   Send a mail to [Torsten Gippert](mailto:torsten.gippert@itergo.com) with your project name. He will create a namespace for your Docker images and send you examples on how to get started.

3. **Install tools**:  
   A couple of tools are required for setting up and interacting with the cluster (i.e. awscli, kubectl, helm and sops). To make it easy to get started, run `./scripts/install-prerequisites.sh` (supports Mac and Linux).
