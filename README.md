# 얼라희  
얼라희는 [아희](http://aheui.github.io/)의 얼랭(erlang) 구현체입니다.  

## 실행  

    $ erlc erlaheui.erl
    $ erl -noshell -eval "erlaheui:c(\"hello-world.puzzlet.aheui\"), init:stop()"
    Hello, world!
    $ 

경로를 \\"로 감싸는 걸 잊으면 안됩니다.

## 아희 표준 [snippets](https://github.com/aheui/snippets) 테스트  

얼랭 가상머신 실행파일을 래핑했기 때문에 exit code에 대한 자동 테스트는 할 수 없습니다.  
직접 비교해보니 맞긴 함.  

    $ ./test.sh [테스트셋 = standard]
    test bieup-char...success!
    test bieup-sign...success!
    test bieup...success!
    ...
    test status: 31/33
    $ 

|# |테스트코드          |통과              |
|--|--------------------|------------------|
|1 |bieup-char          |:heavy_check_mark:|
|2 |bieup-sign          |:heavy_check_mark:|
|3 |bieup               |:heavy_check_mark:|
|4 |border              |:heavy_check_mark:|
|5 |chieut              |:heavy_check_mark:|
|6 |default-direction   |:heavy_check_mark:|
|7 |default-storage     |:heavy_check_mark:|
|8 |digeut              |:heavy_check_mark:|
|9 |emptyswap           |N/A|
|10|exhausted-storage   |:heavy_check_mark:|
|11|exitcode            |N/A|
|12|hieut-pop           |:heavy_check_mark:|
|13|ieunghieut          |:heavy_check_mark:|
|14|jieut               |:heavy_check_mark:|
|15|loop                |:heavy_check_mark:|
|16|mieum               |:heavy_check_mark:|
|17|nieun               |:heavy_check_mark:|
|18|pieup               |:heavy_check_mark:|
|19|print               |:heavy_check_mark:|
|20|queue               |:heavy_check_mark:|
|21|rieul               |:heavy_check_mark:|
|22|shebang             |:heavy_check_mark:|
|23|ssangbieup          |:heavy_check_mark:|
|24|ssangdigeut         |:heavy_check_mark:|
|25|ssangsiot           |:heavy_check_mark:|
|26|storage             |:heavy_check_mark:|
|27|syllable            |:heavy_check_mark:|
|28|tieut               |:heavy_check_mark:|
|29|vowel-2step         |:heavy_check_mark:|
|30|vowel-advanced      |:heavy_check_mark:|
|31|vowel-basic         |:heavy_check_mark:|
|32|vowel-useless       |:heavy_check_mark:|
|33|vowel-useless2      |:heavy_check_mark:|
|34|quine.puzzlet.40col |:heavy_check_mark:|
|35|quine.puzzlet       |:heavy_check_mark:|

## 개발환경  

얼라희는 다음 환경에서 개발하였습니다.  

|Erlang emulator|Erlang OTP|
|---------------|----------|
|5.10.4         |R16B03-1  |  

