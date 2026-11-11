vps := "root@72.62.125.38"
raspi := "ms@raspi.local"

default:
    @just --list

deploy:
    clan machines update hostinger --build-host {{vps}} --target-host {{vps}}

provision machine ip:
    clan machines install {{machine}} --target-host root@{{ip}} --build-on remote

deploy-raspi:
    clan machines update raspi --build-host {{raspi}} --target-host {{raspi}}
