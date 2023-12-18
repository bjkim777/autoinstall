## 개요
환경 자동 배포 및 설치

## 실행 환경
 - ansible 2.16.0
  - python version = 3.10.8 (main, Nov 24 2022, 14:13:03) [GCC 11.2.0]
  - jinja version = 3.1.2

## 인터페이스
해당사항 없음

## 작업 순서
### PXE setting 
```shell
$ bash centos7_pxe_server_setting.sh # 내부 코드 확인 
```

## 설명
```shell
.
├── README.md
├── centos7_pxe_server_setting.sh
├── ks.cfg
└── servers.yml
```

 - `centos7_pxe_server_setting.sh` : CentOS7 기반 pxe server setting
 - `ks.cfg` : KickStart 설정 파일
 - `servers.yml` : ansible 입력 파일 예시


## 버전 및 릴리즈 노트

