ACCOUNT="371212343874"
REGION="ap-south-1"
NAME="openjdk"
REPOSITORY_URI="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${NAME}"
# 371212343874.dkr.ecr.ap-south-1.amazonaws.com/openjdk
VERSION="11-jre"

# docker build -t $NAME .

# #aws-login 
$(aws ecr get-login --no-include-email --region $REGION)
docker tag $NAME:$VERSION $REPOSITORY_URI:$VERSION
docker push $REPOSITORY_URI:$VERSION
