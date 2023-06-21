pipeline {
    agent any
    tools {
        maven 'mvn'
    }
    options {
        skipStagesAfterUnstable()
    }
    environment {
        NODE_VERSION = '16'
        ALPINE_VERSION = '3.15'
        AWS_DEFAULT_REGION = 'us-east-1'
        SSL_CERT_ARN = '<CERT_ARN>'
        ALB_NAME = 'eks-app-internet-lb'
        INGRESSCLASSNAME = 'dev-lb-class'
        LOADBALANCERNAME = 'eks-app-internet-lb'
        CERTIFICATE_ARN = '<CERTIFICATE_ARN>'
        EKS_CLUSTER_NAME = 'dev-products'
        EKS_KUBECTL_ROLE_ARN = '<EKS_ARN>'
        BUILDENVVALUE = 'development'      
        DOCKERHUB_USERNAME = 'DOCKERHUB_USERNAME'
        DOCKERHUB_PASS = 'DOCKERHUB_PASS'
        Build_Env = 'development'
        environ = 'development'
        ValueUrl = 'Value_FOR_HOSTURL'
 
        AWS_Access_Key_Id = '<KEY_ID>
        AWS_Secret_access_key = '<SECRET_KEY>'
        AWS_SESSION_TOKEN = '<TOKEN>'
    }
    stages {
        
        stage ("Prompt for input") {
         steps {
           script {
             env.REPONAME = input message: 'Please enter the REPONAME',
                                parameters: [string(defaultValue: '',
                                             description: '',
                                             name: 'Reponame')]
             env.PORT = input message: 'Please enter the port',
                                parameters: [password(defaultValue: '',
                                             description: '',
                                             name: 'Port')]
             env.BRANCH = input message: 'Please enter the Branch',
                                parameters: [string(defaultValue: '',
                                             description: '',
                                             name: 'Branch')]
           }
           echo "Reponame: ${env.REPONAME}"
           echo "Port: ${env.PORT}"
           echo "Branch:  ${env.BRANCH}"
         } 
        }
       
        

        stage('Clone repository') { 
            steps { 
                script{
                     sh 'git gc --prune=now'
                    //sh 'git remote prune origin'
                    checkout([$class: 'GitSCM', branches: [[name: "${BRANCH}"]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'rwrbitbucket', url: "https://chingaricicd:h8ERJnv2nfcdjRSzbxXE@bitbucket.org/sumitghosh/$NAMESPACE"]]])     
                
                }
            }
        }
        stage('Initialize'){
            steps {
                script{
            
               def dockerHome = tool 'myDocker'
               env.PATH = "${dockerHome}/bin:${env.PATH}"
                }
            }    
        } 
        stage('Create Ecr') {
            steps {
                script{
                    sh 'curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -'
                    sh 'apt-get update && apt-get -y install jq python3-pip python3-dev && pip3 install --upgrade awscli'
               
                    sh 'curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - '
                    sh 'curl -sS -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator'
                    sh 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
                    sh 'install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl'
                    sh 'chmod +x ./aws-iam-authenticator'
                    sh 'kubectl version --client'
                    //till yha tak
                    sh 'apt-get update && apt-get install -y python-dev jq'
                    sh 'curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py'
            //        sh 'curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"'
             //       sh 'unzip -u awscliv2.zip'
               //     sh './aws/install --update'
               //     sh './aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update'
               //     sh 'which aws'
               //     sh 'ls -l /usr/local/bin/aws'
                   // sh 'python get-pip.py'
                    sh 'pip install awscli'
                    sh 'which aws'
                    
                    sh 'pip install docker'
                    sh 'pip install --upgrade docker'
                    sh 'pip install sudo'
                    sh 'id -nG'
                    sh 'docker'
                    sh 'curl -fsSL https://get.docker.com -o get-docker.sh'
                    sh 'sh get-docker.sh'
                    sh 'usermod -aG docker jenkins'
                    sh 'systemctl enable docker'
                    sh 'curl -LO "https://dl.k8s.io/release/v1.18.9/bin/linux/amd64/kubectl"'
                    sh 'install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl'
                    sh 'export PATH=$PWD/:$PATH'
                    sh 'kubectl version --client'
                    sh 'cd $CODEBUILD_SRC_DIR'
                    sh 'echo $CODEBUILD_SRC_DIR'
                    sh '''
                   
                    if [[ $(service docker start 2>&1) =~ "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?" ]]; then
                      echo "docker is already running"
                    else
                      echo "docker is now running"
                      
                    fi
                    '''                
                    sh 'aws configure set aws_access_key_id "$AWS_Access_Key_Id"'
                    sh 'aws configure set aws_secret_access_key "$AWS_Secret_access_key"'
                    sh 'aws configure set aws_session_token "$AWS_SESSION_TOKEN"'
                    sh 'aws eks update-kubeconfig --region us-east-1 --name dev-products' 
                   
                    sh '''
                    
                    #!/bin/bash
                    
                    
                   
                    if [[ $(kubectl create namespace ${REPONAME} 2>&1) =~ "Error from server (AlreadyExists)" ]]; then
                      echo "namespace already exists."
                    else
                      echo "namespace created"
                      
                    fi

               
                    
                    '''
                    
                    sh "aws --version"
                    sh '''
                    #!/bin/bash
                    if [[ $(aws ecr create-repository --repository-name ${NAMESPACE} --image-scanning-configuration scanOnPush=true  --encryption-configuration '{"encryptionType":"KMS"}' 2>&1) =~ "An error occurred (RepositoryAlreadyExistsException) when calling the CreateRepository operation" ]]; then
                      echo "ecr have to created"
                      aws ecr create-repository --repository-name ${NAMESPACE} --image-scanning-configuration scanOnPush=true 
                    else
                      echo "alreday have ecr"
                    fi
                    
                    '''
                    

                }
            }
        }           
    
        stage("route53 creation") {
            steps {
                script{
                    sh '''
                    if [[ $(aws route53 change-resource-record-sets --hosted-zone-id <ZONEID> --change-batch '{ "Comment": "Testing creating a record set", "Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name": "'$REPONAME'.<abcd>.io", "Type": "A", "AliasTarget": { "DNSName": "<DNS_NAME>", "HostedZoneId": "<ZONEID>", "EvaluateTargetHealth": true }  } } ] }' --region us-east-1 2>&1) =~ "An error occurred (InvalidChangeBatch) when calling the ChangeResourceRecordSets operation" ]]; then
                      echo "Route53url already exists."
                    else
                      echo "Route53url created"
                      
                    fi

                    ''' 
                    sh 'export Hurl=$REPONAME.chingari.io'

                                         

                }
            }
        }     
    
    


        stage('Push') {
            steps {
                script{
                        //sh 'aws ecr get-login-password --region us-east-1'
                        sh '''
                
                        docker login -u AWS https://<1234567>.dkr.ecr.us-east-1.amazonaws.com -p $(aws ecr get-login-password --region us-east-1)
                        docker tag $REPONAME:latest <12345678>.dkr.ecr.us-east-1.amazonaws.com/$REPONAME:latest
                        docker push 463877552462.dkr.ecr.us-east-1.amazonaws.com/$REPONAME:latest
                        '''
  
               
                    
                }
            }
        }

    
        stage('Deploy App to kuberentes') {
          steps {
              
          
             
            script {
      
                sh "sed -i 's@NAMESPACE@'$REPONAME'@' k8s/deployment.yaml"
                sh "sed -i 's@DEPLOYMENTNAME@'$BRANCH'@' k8s/deployment.yaml"
                sh "sed -i 's@BUILDENVVALUE@'$BUILDENVVALUE'@' k8s/deployment.yaml"
                sh "sed -i 's@imageid@'463877552462.dkr.ecr.us-east-1.amazonaws.com/$REPONAME:latest'@' k8s/deployment.yaml"
                sh "sed -i 's@NAMESPACE@'$REPONAME'@' k8s/service.yaml"
                sh "sed -i 's@SERVICENAME@'$BRANCH'@' k8s/service.yaml"
                sh "sed -i 's@LOADBALANCERNAME@'$LOADBALANCERNAME'@' k8s/ingress.yaml"
                sh "sed -i 's@INGRESSNAME@'$BRANCH'@' k8s/ingress.yaml"
                sh "sed -i 's@NAMESPACE@'$REPONAME'@' k8s/ingress.yaml"
                sh "sed -i 's@INGRESSCLASSNAME@'$INGRESSCLASSNAME'@' k8s/ingress.yaml"            
                sh "sed -i 's@HOSTURL@'$Hurl'@' k8s/ingress.yaml"
                sh "sed -i 's@PORT@'$PORT'@' k8s/ingress.yaml"
                sh "sed -i 's@SERVICENAME@'$BRANCH'@' k8s/ingress.yaml"
                sh "sed -i 's@CERTIFICATE_ARN@'$CERTIFICATE_ARN'@' k8s/ingress.yaml"
                sh "sed -i 's@DEPLOYMENTNAME@'$BRANCH'@' k8s/hpa.yaml"
                sh "sed -i 's@NAMESPACE@'$REPONAME'@' k8s/hpa.yaml"
                sh 'cat k8s/deployment.yaml'
                sh 'cat k8s/ingress.yaml'
                sh 'cat k8s/service.yaml'
                  
        
                sh 'kubectl get pods -n ${REPONAME}'
                sh 'kubectl apply -f k8s/.'
                sh 'kubectl get pods -n ${REPONAME}'
                sh 'kubectl get all -n ${REPONAME}'

                
            }  
            
          }
        } 
        
               


      }
}      
