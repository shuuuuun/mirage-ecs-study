AWS_REGION := ap-northeast-1
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity | jq -r '.Account')

BASE_DOMAIN := ${BASE_DOMAIN}

COPILOT_APP_NAME := mirage-ecs-study
COPILOT_ENV_NAME := dev
COPILOT_SVC_NAME := mirage

# $ aws ecs list-clusters | jq -rc '.clusterArns[] | select(contains("cluster/mirage-ecs-study-dev-Cluster-"))' | sed -e "s@^.*cluster/@@g"
# $ aws ec2 describe-vpcs | jq -rc '.Vpcs[] | select(.Tags[] | select(.Key=="Name"))'
# $ aws ec2 describe-vpcs --filters "Name=tag:Name,Values=copilot-mirage-ecs-study-dev"
# $ aws ec2 describe-subnets --filters "Name=tag:copilot-application,Values=mirage-ecs-study" --filters "Name=tag:copilot-environment,Values=dev" | jq '.Subnets[] | { SubnetId: .SubnetId, VpcId: .VpcId, MapPublicIpOnLaunch: .MapPublicIpOnLaunch, Name: (.Tags[] | select(.Key=="Name").Value) }'
# $ aws ec2 describe-subnets --filters "Name=tag:copilot-application,Values=mirage-ecs-study" --filters "Name=tag:copilot-environment,Values=dev" | jq -rc 'first(.Subnets[] | select(.MapPublicIpOnLaunch == true).SubnetId)')
# $ aws ec2 describe-security-groups | jq -rc '.SecurityGroups[] | select(.GroupName | startswith("mirage-ecs-study-dev-EnvironmentSecurityGroup")).GroupId'
# $ aws route53 list-hosted-zones-by-name --dns-name dev.mirage-ecs-study.example.com. | jq '.HostedZones[] | select(.Name == "dev.mirage-ecs-study.example.com.")'
export CLUSTER := $(shell aws ecs list-clusters | jq -rc '.clusterArns[] | select(contains("cluster/${COPILOT_APP_NAME}-${COPILOT_ENV_NAME}-Cluster-"))' | sed -e "s@^.*cluster/@@g")
PUBLIC_SUBNETS := $(shell aws ec2 describe-subnets --filters "Name=tag:copilot-application,Values=${COPILOT_APP_NAME}" --filters "Name=tag:copilot-environment,Values=${COPILOT_ENV_NAME}" | jq -rc '.Subnets[] | select(.MapPublicIpOnLaunch == true).SubnetId')
export SUBNET_1 := $(word 1,${PUBLIC_SUBNETS})
export SUBNET_2 := $(word 2,${PUBLIC_SUBNETS})
export SECURITY_GROUP := $(shell aws ec2 describe-security-groups | jq -rc '.SecurityGroups[] | select(.GroupName | startswith("${COPILOT_APP_NAME}-${COPILOT_ENV_NAME}-EnvironmentSecurityGroup")).GroupId')
export DEFAULT_TASKDEF := arn:aws:ecs:ap-northeast-1:${AWS_ACCOUNT_ID}:task-definition/mirage-ecs-printenv:1
export DOMAIN := ${COPILOT_ENV_NAME}.${COPILOT_APP_NAME}.${BASE_DOMAIN}
export HOSTED_ZONE_ID := $(shell aws route53 list-hosted-zones-by-name --dns-name ${DOMAIN}. | jq -rc '.HostedZones[] | select(.Name == "${DOMAIN}.").Id')

.PHONY: copilot/*

printenv:
	printenv

build:
	docker build --tag mirage-ecs-study ./

run-sh:
	docker run --rm -it --entrypoint sh mirage-ecs-study

copilot/ls:
	copilot app ls
	copilot env ls
	copilot svc ls

copilot/init: copilot/init-app copilot/init-env copilot/init-svc
copilot/init-app:
	copilot app init ${COPILOT_APP_NAME} --domain ${BASE_DOMAIN}
copilot/init-env:
	copilot env init --name ${COPILOT_ENV_NAME} --app ${COPILOT_APP_NAME}
copilot/init-svc:
	copilot svc init --name ${COPILOT_SVC_NAME}

copilot/deploy:
	copilot svc deploy --name ${COPILOT_SVC_NAME} --env ${COPILOT_ENV_NAME}
copilot/deploy-force:
	copilot svc deploy --name ${COPILOT_SVC_NAME} --env ${COPILOT_ENV_NAME} --force

copilot/delete: copilot/delete-svc copilot/delete-env copilot/delete-app
copilot/delete-app:
	copilot app delete --name ${COPILOT_APP_NAME}
copilot/delete-env:
	copilot env delete --name ${COPILOT_ENV_NAME}
copilot/delete-svc: detach-role-policy
	copilot svc delete --name ${COPILOT_SVC_NAME}

# $ aws iam list-roles | jq -rc '.Roles[] | select(.RoleName | startswith("mirage-ecs-study-dev-mirage-TaskRole-"))'
task_role_name := $(shell aws iam list-roles | jq -rc '.Roles[] | select(.RoleName | startswith("${COPILOT_APP_NAME}-${COPILOT_ENV_NAME}-${COPILOT_SVC_NAME}-TaskRole-")).RoleName')
attach-role-policy:
	aws iam attach-role-policy --role-name ${task_role_name} --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
detach-role-policy:
	test -n "${task_role_name}" && \
	aws iam detach-role-policy --role-name ${task_role_name} --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess || exit 0

# aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/ZXXXXXXXXXX | jq '.ResourceRecordSets[]'
list-resource-record-sets:
	aws route53 list-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} | jq -rc '.ResourceRecordSets[]'
# aws route53 change-resource-record-sets --hosted-zone-id ZXXXXXXXXXX --change-batch file://sample.json
