#!/bin/bash
# 도커 컴포즈 실행

# 버전 정보 가져오기
source .version

# 네트워크 정보 가져오기
source .network

# .secret 파일 확인
Secret_File=.secret

if [[ -f ~/"$Secret_File" ]]; then
    source ~/$Secret_File
    
else
    echo -e "\e[43;31mERROR!\e[0m"
    echo "$Secret_File file could not be found." 
    echo -e "Exit the task. Error Code \e[43;31m101\e[0m"
    exit 101
fi

# 도커 네트워크 확인
echo "##### Start Network Verification #####"

for check_net in ${docker_net[@]}
do
    if [[ "$(docker network ls)" != *$check_net* ]]; then
        # 없을 때 생성
        echo "Could not find [ $check_net ] network."
        echo "Creating [ $check_net ] network."
        docker network create $check_net > /dev/null
        echo "Done!"

    else
        echo "[ $check_net ] network already exists."
    fi
done

echo "##### Finish Network Verification #####"
echo ""

# 각 폴더명 추출해서 set_env.sh 선행 실행
for entry in */
do
    # .secret에 함수로 지정된 변수 불러오기
    ${entry:0:-1} 2> /dev/null || func_res=$?

    # source 함수 제대로 있는지 확인하는 과정
    if [[ "${func_res}" != 200 ]]; then
        echo "${entry:0:-1} is not found!"
        echo "Check $Secret_File file"
        exit 102
    fi
    
    # set_env.sh 있으면 실행
    if [[ -f "${entry:0:-1}/set_env.sh" ]]; then
        # set_env.sh 퍼미션주고 실행하기
        chmod 744 ./${entry:0:-1}/set_env.sh
        ./${entry:0:-1}/set_env.sh

    else
        echo "${entry:0:-1}/set_env.sh is UNAVAILABLE"
        echo "Skip ${entry:0:-1}/set_env.sh"
    fi
done

echo "##### Run Docker-compose ######"
echo ""

for entry in */
do
    # 각 폴더에 저장된 docker-compose 실행
    docker-compose -f ./${entry:0:-1}/docker-compose.yml up -d
done

echo ""
echo "##### DONE! ######"
