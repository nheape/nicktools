#! /bin/bash
#: Title: addkubeuser-mac.sh
#: Author: Nick Heape
#: Version: 1.0
#: Description: Add a kubernetes user to an existing cluster (OS X version)
#: Options: None

# Get the info

AWS_ACCOUNT=`aws sts get-caller-identity --output text --query 'Account'`

echo "
Enter the username to add to this Kubernetes cluster."
read _USERNAME 

echo "
Username: $_USERNAME
AWS Account: $AWS_ACCOUNT

Is this correct? (y/n)
"
read _CONFIRMATION

if [ $_CONFIRMATION != "y" ]; then
echo "Terminating."
exit 2
fi

echo "Adding arn:aws:iam::$AWS_ACCOUNT:user/$_USERNAME to Kubernetes users"

# Download current configmap as yaml
kubectl get -n kube-system configmap/aws-auth -o yaml > ./current-configmap.yaml

# If there are already users, add the user. If there are no users defined, add mapUsers section and add the user. Output as updated-configmap.yaml
if [ `cat ./current-configmap.yaml | grep mapUsers | wc -l` -ge "1" ]; then awk '/kind:\ ConfigMap/{print "    - userarn: arn:aws:iam::AWSACCOUNTNUMBER:user/KUBEUSERNAME\n      username: KUBEUSERNAME\n      groups:\n        - system:masters"}1' current-configmap.yaml > updated-configmap.yaml; else awk '/kind:\ ConfigMap/{print "  mapUsers: |\n    - userarn: arn:aws:iam::AWSACCOUNTNUMBER:user/KUBEUSERNAME\n      username: KUBEUSERNAME\n      groups:\n        - system:masters"}1' current-configmap.yaml > updated-configmap.yaml; fi

# Update username and account number
sed -i "" "s/KUBEUSERNAME/$_USERNAME/g" ./updated-configmap.yaml
sed -i "" "s/AWSACCOUNTNUMBER/$AWS_ACCOUNT/g" ./updated-configmap.yaml

# Apply the changes
kubectl apply -f updated-configmap.yaml
echo "
User $_USERNAME Added! New configmap displayed below.
"

kubectl get -n kube-system configmap/aws-auth -o yaml

# Cleanup steps - comment out to troubleshoot
rm current-configmap.yaml; rm updated-configmap.yaml
