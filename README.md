# <span id="top">AlwaysOn 2차 팀프로젝트</span>

### 📢 Commit Message Rules

- 작은 기능이라도 구현이 완료되면 커밋하여 반영 사항을 확인할 수 있도록 합니다.
- 커밋 유형 이후 제목과 본문은 한글로 작성하여 내용이 잘 전달될 수 있도록 합니다.
- 커밋 메시지는 누구나 이해할 수 있게 작성합니다.


<br>

### 📌 Commit Convention

**[커밋 유형]  커밋 메시지**

| 커밋 유형 |                       의미                        |
| :-------: | :-----------------------------------------------: |
|   Feat    |             새로운 기능 추가                       |
|    Fix    |                 버그 수정                          |
|   Design   |                UI 디자인 변경                     |
|   Chore   |           패키지 매니저 수정, 기타 수정             |
|   Docs    |                 문서 수정                          |
|  Rename   |         파일 또는 폴더 명을 수정 및 이동            |
|  Remove   |            파일 또는 폴더 삭제                     |
|   Style   |          코드 의미와 무관한 변경 사항               |
| Refactor  |               코드 리팩토링                        |

예시 >

```
  Feat. S3 버킷 생성
```


<br>


### 📌 Gitflow Rules
1. devleop 브랜치에 직접적인 commit, push는 금지합니다.
   - 모든 작업은 각자의 feature 브랜치에서 진행됩니다.
     
2. 기능 구현 시작 전 issue를 생성합니다.
   - projects 탭에서 해당 기능과 관련된 issue를 작성하고, issue에 맞는 feature 브랜치를 생성합니다.
  
3. 기능 구현이 완료되지 않은 경우에는 각자의 feature 브랜치에 커밋을 진행하며, 완료되면 develop 브랜치로 PR을 보냅니다.
  
4. PR은 팀원들의 코드 리뷰가 완료된 후 devleop 브랜치에 merge 할 수 있습니다.  


<br>
