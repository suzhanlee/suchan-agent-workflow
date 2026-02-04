# PLAN - atdd-tdd-workflow

## Context

### Original Request

"ATDD - TDD 워크플로우를 만들고 싶다"

사용자가 Java/Spring 프로젝트에서 ATDD (Acceptance Test Driven Development) + TDD (Test Driven Development) 프로세스를 자동화하는 Claude Code 스킬을 생성하고자 함.

### Interview Summary

| 결정 항목 | 선택 |
|----------|------|
| 언어/프레임워크 | Java + Spring Boot |
| 자동화 수준 | 단계별 가이드 (사용자 승인 필요) |
| Acceptance Test | Cucumber + Gherkin (Given-When-Then) |
| Controller Test | REST Assured |
| 코드 생성 범위 | TDD 원칙 (기본 동작 코드 + 리팩토링 가능) |
| 테스트 데이터 설정 | **JPA repository.save()** (SQL 생성 에이전트 제거로 단순화) |
| 테스트 DB | MySQL Testcontainers only |
| 스킬 구조 | 2개 스킬 (atdd-init, atdd-generate) |
| 에이전트 | 3개 (criteria-generator, test-writer, code-writer) |

### Research Findings

**SQL Test Data 관리 Best Practice:**
- Per-Scenario SQL Files가 Cucumber에 적합하지만
- 본 프로젝트에서는 **JPA `repository.save()`** 사용으로 단순화
- 타입 안전성, 자동 정리, 트랜잭션 롤백 등 Spring이 처리

**Spring Boot Testing:**
- Cucumber + Spring Boot 통합: `@CucumberContextConfiguration`
- REST Assured: `@LocalServerPort`로 random port 지원
- MySQL Testcontainers: Singleton 패턴으로 성능 최적화

---

## Work Objectives

### Concrete Deliverables

1. **`/atdd-init` 스킬**
   - User Story 입력 → Gherkin Feature 파일 생성
   - SKILL.md 정의

2. **`/atdd-generate` 스킬**
   - Gherkin Feature → Cucumber Tests → Production Code → Refactor
   - SKILL.md 정의

3. **3개 에이전트**
   - `atdd-criteria-generator.md`
   - `atdd-test-writer.md`
   - `atdd-code-writer.md`

4. **MySQL Testcontainers 설정**
   - build.gradle/pom.xml 의존성 가이드

### Must NOT Do

- 실제 DB 스키마 마이그레이션 (Flyway/Liquibase)
- 운영 환경 설정 파일 생성
- CI/CD 파이프라인 설정
- @SpringBootTest만 사용 (slice tests 적절히 사용)
- Hardcoded port 8080 (REST Assured)
- SQL 파일 생성 대신 JPA 사용

### Definition of Done

1. `/atdd-init` 실행 시 User Story → .feature 파일 생성
2. `/atdd-generate` 실행 시 .feature → 테스트 → 코드 → 리팩토링
3. 생성된 테스트가 `./gradlew test`로 실행 가능
4. MySQL Testcontainers로 통합 테스트 가능
5. 각 단계 후 사용자 승인 프로세스 동작

---

## Templates

### SKILL.md Template

```markdown
---
name: atdd-init
description: |
  User Story를 Gherkin Feature 파일로 변환하는 스킬
allowed-tools:
  - Task
  - Write
  - Read
  - Edit
disallowed-tools:
  - Bash
---

# /atdd-init - User Story to Gherkin Feature

## Usage

```
/atdd-init
```

## Steps

1. User Story를 입력받습니다
2. atdd-criteria-generator 에이전트를 호출하여 Gherkin AC를 생성합니다
3. .feature 파일로 저장합니다
4. 사용자 승인을 요청합니다
```

### Agent Template

```markdown
---
model: sonnet
role: criteria-generator
---

# atdd-criteria-generator

## Role

User Story를 Gherkin (Given-When-Then) 형식의 Acceptance Criteria로 변환합니다.

## Input

User Story (자연어)

## Output

Gherkin Feature 파일 (.feature)

## Guidelines

- Given: 시스템 초기 상태
- When: 사용자 액션
- Then: 예상 결과
- Background: 모든 시나리오에 공통인 전제 조건
```

### Gherkin Feature Example

```gherkin
Feature: User Registration

  Background:
    Given the application is running

  Scenario: Successful registration
    Given user navigates to registration page
    When user enters valid email and password
    Then user account is created
    And user is redirected to dashboard
```

---

## Orchestrator Section

### Task Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    /atdd-init Workflow                          │
├─────────────────────────────────────────────────────────────────┤
│  1. User Story 입력                                             │
│     ↓                                                           │
│  2. atdd-criteria-generator 에이전트 호출                        │
│     → Gherkin AC 생성                                           │
│     ↓                                                           │
│  3. .feature 파일 저장                                          │
│     → src/test/resources/features/{name}.feature                │
│     ↓                                                           │
│  4. 사용자 승인 요청                                            │
│     → "이 AC가 맞나요?"                                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   /atdd-generate Workflow                        │
├─────────────────────────────────────────────────────────────────┤
│  1. .feature 파일 로드                                           │
│     ↓                                                           │
│  2. atdd-test-writer 에이전트 호출                               │
│     → Glue code (Step Definitions) 작성                         │
│     → REST Assured 패턴 적용                                     │
│     → JPA @Before 데이터 설정                                   │
│     ↓                                                           │
│  3. 테스트 실행 (Red - 실패 예상)                                │
│     → ./gradlew test                                            │
│     ↓                                                           │
│  4. 사용자 승인 요청                                            │
│     → "테스트가 실패하나요?"                                    │
│     ↓                                                           │
│  5. atdd-code-writer 에이전트 호출                               │
│     → Entity, Service, Controller 작성                          │
│     → TDD 원칙: 기본 동작 코드                                   │
│     ↓                                                           │
│  6. 테스트 실행 (Green - 성공 확인)                              │
│     → ./gradlew test                                            │
│     ↓                                                           │
│  7. Refactoring 제안                                            │
│     → 테스트 재실행 (회귀 확인)                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Dependency Graph

```
atdd-init 스킬
  └── atdd-criteria-generator 에이전트
       └── .feature 파일 생성

atdd-generate 스킬
  ├── atdd-test-writer 에이전트
  │    └── .feature 파일 입력
  └── atdd-code-writer 에이전트
       └── Glue code 입력
```

### Parallelization

- 각 에이전트는 순차 실행 (워크플로우 특성상 병렬화 불가)
- 여러 User Story를 병렬로 처리할 수 있도록 설계 (확장성)

### Commit Strategy

- TODO 단위로 커밋 (Orchestrator만 git 사용)
- 커밋 메시지: `[atdd] {feature-name}: {description}`

### Error Handling

- 테스트 실패 시 사용자에게 안내 후 재시도
- 컴파일 에러 시 코드 수정 후 재실행
- MySQL 컨테이너 실패시 Docker 상태 확인 안내

### Runtime Contract

**Inputs:**
- `/atdd-init`: User Story (free text)
- `/atdd-generate`: .feature 파일 경로

**Outputs:**
- `/atdd-init`: .feature 파일
- `/atdd-generate`: Glue code, Production code

**Guarantees:**
- 생성된 코드는 컴파일 가능
- 테스트는 실행 가능 (성공 여부는 별도)
- MySQL Testcontainers 연동됨

---

## TODOs

### TODO 1: atdd-init 스킬 구조 설계

**Type:** work
**Required Tools:** Write, Edit, Read
**Inputs:** User Story (사용자 입력)
**Outputs:** `.claude/skills/atdd-init/SKILL.md`

**Steps:**
- [ ] SKILL.md frontmatter 작성 (name, description, allowed-tools)
- [ ] 스킬 동작 흐름 문서화
- [ ] 사용자 입력 가이드 작성
- [ ] atdd-criteria-generator 에이전트 호출 방법 정의

**Must NOT do:**
- git 명령어 실행
- src/main/java 수정

**References:**
- SKILL.md Template (위 Templates 섹션 참고)

**Verify:**
```yaml
acceptance:
  functional:
    - given: ["사용자가 /atdd-init를 실행"]
      when: "User Story를 입력"
      then: [".feature 파일이 생성됨", "Gherkin 형식이 맞음"]
  static:
    - run: "test -f .claude/skills/atdd-init/SKILL.md"
      expect: "exit 0"
    - run: "head -1 .claude/skills/atdd-init/SKILL.md | grep '^---'"
      expect: "exit 0"
  runtime:
    - run: "grep -c 'allowed-tools:' .claude/skills/atdd-init/SKILL.md"
      expect: "stdout > 0"
risk: LOW
```

---

### TODO 2: atdd-generate 스킬 구조 설계

**Type:** work
**Required Tools:** Write, Edit, Read, Bash
**Inputs:** .feature 파일 경로
**Outputs:** `.claude/skills/atdd-generate/SKILL.md`

**Dependencies:** TODO 1

**Steps:**
- [ ] SKILL.md frontmatter 작성
- [ ] 스킬 동작 흐름 문서화 (Test → Code → Refactor)
- [ ] atdd-test-writer, atdd-code-writer 호출 방법 정의
- [ ] 단계별 승인 프로세스 정의
- [ ] 테스트 실행 명령어 정의 (`./gradlew test`)
- [ ] Stop hook 작성 (단계 전이 자동화)
- [ ] settings.json에 hook 등록

**Must NOT do:**
- git 명령어 실행
- 사용자 승인 없이 production 코드 수정

**References:**
- SKILL.md Template (위 Templates 섹션 참고)

**Verify:**
```yaml
acceptance:
  functional:
    - given: [".feature 파일이 존재"]
      when: "/atdd-generate 실행"
      then: ["Glue code 생성됨", "Production code 생성됨", "테스트 실행됨"]
  static:
    - run: "test -f .claude/skills/atdd-generate/SKILL.md"
      expect: "exit 0"
    - run: "head -1 .claude/skills/atdd-generate/SKILL.md | grep '^---'"
      expect: "exit 0"
  runtime:
    - run: "grep -c 'allowed-tools.*Bash' .claude/skills/atdd-generate/SKILL.md"
      expect: "stdout > 0"
risk: LOW
```

---

### TODO 3: atdd-criteria-generator 에이전트 구현

**Type:** work
**Required Tools:** Write, Read
**Inputs:** User Story
**Outputs:** `.claude/agents/atdd-criteria-generator.md`

**Dependencies:** TODO 1

**Steps:**
- [ ] 에이전트 frontmatter 작성 (model: sonnet, role: criteria-generator)
- [ ] User Story → Gherkin 변환 프롬프트 작성
- [ ] Given-When-Then 패턴 가이드
- [ ] Scenario Outline 지원
- [ ] Background 섹션 지원

**Must NOT do:**
- git 명령어 실행
- .feature 파일 외 생성

**References:**
- Agent Template (위 Templates 섹션 참고)
- Gherkin Feature Example (위 Templates 섹션 참고)
- Cucumber Gherkin syntax

**Verify:**
```yaml
acceptance:
  functional:
    - given: ["User Story 입력"]
      when: "에이전트 실행"
      then: ["Given-When-Then 형식", "Feature 파일 생성됨"]
  static:
    - run: "test -f .claude/agents/atdd-criteria-generator.md"
      expect: "exit 0"
    - run: "head -1 .claude/agents/atdd-criteria-generator.md | grep '^---'"
      expect: "exit 0"
  runtime:
    - run: "grep -c 'model:' .claude/agents/atdd-criteria-generator.md"
      expect: "stdout > 0"
risk: MEDIUM
```

---

### TODO 4: atdd-test-writer 에이전트 구현

**Type:** work
**Required Tools:** Write, Read, Bash
**Inputs:** .feature 파일
**Outputs:** Glue code, Test configuration

**Dependencies:** TODO 2

**Steps:**
- [ ] 에이전트 frontmatter 작성 (model: sonnet, role: test-writer)
- [ ] .feature 파싱 프롬프트 작성
- [ ] Step Definitions 생성 (@Given, @When, @Then)
- [ ] REST Assured 패턴 적용 (given-when-then)
- [ ] JPA @Before 데이터 설정 (repository.save())
- [ ] @SpringBootTest 설정 + @LocalServerPort
- [ ] MySQL Testcontainers 설정 (@Testcontainers, MySQLContainer)
- [ ] AssertJ assertThat 사용

**Must NOT do:**
- git 명령어 실행
- src/main/java 수정
- @SpringBootTest만 사용 (slice tests 고려)

**References:**
- Cucumber + Spring Boot integration
- REST Assured documentation
- MySQL Testcontainers guide

**Verify:**
```yaml
acceptance:
  functional:
    - given: [".feature 파일 존재"]
      when: "에이전트 실행"
      then: [
        "Step Definitions 생성됨",
        "REST Assured 패턴 적용됨",
        "JPA 데이터 설정됨",
        "Glue code가 .feature와 연동됨",
        "REST Assured가 @LocalServerPort 사용",
        "MySQL Testcontainers 설정됨"
      ]
  static:
    - run: "test -f .claude/agents/atdd-test-writer.md"
      expect: "exit 0"
  runtime:
    - run: "grep -r '@Given' src/test/java 2>/dev/null | wc -l | grep -q '[1-9]'"
      expect: "exit 0"
    - run: "grep -r 'RestAssured.given()' src/test/java 2>/dev/null | wc -l | grep -q '[1-9]'"
      expect: "exit 0"
risk: MEDIUM
```

---

### TODO 5: atdd-code-writer 에이전트 구현

**Type:** work
**Required Tools:** Write, Read, Bash
**Inputs:** Glue code, Test failures
**Outputs:** Entity, Service, Controller

**Dependencies:** TODO 4

**Steps:**
- [ ] 에이전트 frontmatter 작성 (model: sonnet, role: code-writer)
- [ ] Test 실패 분석 프롬프트 작성
- [ ] Entity 생성 (JPA annotations, @Entity, @Id, @Column)
- [ ] Service 생성 (interface + impl)
- [ ] Controller 생성 (@RestController, DTOs, @RequestMapping)
- [ ] TDD 원칙: 기본 동작 코드만 (과잉 설계 방지)
- [ ] Refactoring 제안 (코드 개선 안내)
- [ ] 테스트 실행 및 결과 확인 (`./gradlew test`)

**Must NOT do:**
- git 명령어 실행
- Flyway/Liquibase 마이그레이션 생성
- Entity를 Controller에서 직접 반환 (DTO 사용)

**References:**
- Spring Boot REST API best practices
- JPA Entity patterns

**Verify:**
```yaml
acceptance:
  functional:
    - given: ["테스트가 실패 상태"]
      when: "에이전트 실행"
      then: [
        "Entity 생성됨",
        "Service 생성됨",
        "Controller 생성됨",
        "테스트 성공",
        "생성된 코드가 테스트를 통과",
        "DTO를 사용하여 Entity 반환 방지"
      ]
  static:
    - run: "test -f .claude/agents/atdd-code-writer.md"
      expect: "exit 0"
  runtime:
    - run: "find src/main/java -name '*Entity.java' 2>/dev/null | wc -l | grep -q '[1-9]'"
      expect: "exit 0"
    - run: "find src/main/java -name '*Service.java' 2>/dev/null | wc -l | grep -q '[1-9]'"
      expect: "exit 0"
    - run: "find src/main/java -name '*Controller.java' 2>/dev/null | wc -l | grep -q '[1-9]'"
      expect: "exit 0"
risk: MEDIUM
```

---

### TODO 6: MySQL Testcontainers 설정 가이드

**Type:** work
**Required Tools:** Write, Read, Bash
**Inputs:** 없음
**Outputs:** build.gradle/pom.xml 설정 가이드

**Dependencies:** TODO 2

**Steps:**
- [ ] Testcontainers 의존성 추가 (build.gradle 또는 pom.xml)
- [ ] MySQL Testcontainers 설정 예시 작성
- [ ] Singleton 패턴으로 성능 최적화 가이드
- [ ] @Testcontainers 어노테이션 사용 예시
- [ ] MySQLContainer 빈 설정 예시

**Must NOT do:**
- 사용자의 build.gradle/pom.xml을 직접 수정 (가이드만 제공)
- H2 in-memory DB 설정

**References:**
- Testcontainers MySQL documentation
- Spring Boot Testcontainers integration

**Verify:**
```yaml
acceptance:
  functional:
    - given: ["의존성 추가됨"]
      when: "테스트 실행"
      then: ["MySQL 컨테이너 시작됨", "테스트가 실행됨", "Testcontainers가 Spring과 통합됨"]
  static:
    - run: "grep 'testcontainers' build.gradle 2>/dev/null || grep 'testcontainers' pom.xml 2>/dev/null"
      expect: "exit 0"
  runtime:
    - run: "SKIP - requires manual Docker setup and Testcontainers execution"
      expect: "manual"
risk: MEDIUM
```

---

### TODO Final: Verification

**Type:** verification
**Required Tools:** Bash, Read
**Inputs:** 모든 이전 TODOs 출력물
**Outputs:** 검증 결과

**Steps:**
- [ ] SKILL.md 파일 존재 확인 (2개)
- [ ] 에이전트 파일 존재 확인 (3개)
- [ ] YAML frontmatter 유효성 확인
- [ ] Cucumber feature 파일 생성 테스트
- [ ] Glue code 생성 테스트
- [ ] Production 코드 생성 테스트
- [ ] 테스트 실행 가능성 확인 (`./gradlew test`)
- [ ] MySQL Testcontainers 연동 확인

**Must NOT do:**
- git 명령어 실행
- 파일 수정 (read-only)

**Verify:**
```yaml
acceptance:
  functional:
    - given: ["모든 TODO 완료"]
      when: "검증 실행"
      then: [
        "SKILL.md 2개 존재",
        "에이전트 3개 존재",
        "YAML frontmatter 유효",
        "테스트 실행 가능",
        "MySQL 연동됨"
      ]
  static:
    - run: "test -f .claude/skills/atdd-init/SKILL.md && test -f .claude/skills/atdd-generate/SKILL.md"
      expect: "exit 0"
    - run: "ls .claude/agents/atdd-*.md 2>/dev/null | wc -l | grep 3"
      expect: "exit 0"
    - run: "for f in .claude/skills/*/SKILL.md .claude/agents/*.md; do head -1 \"$f\" | grep -q '^---' || exit 1; done"
      expect: "exit 0"
  runtime:
    - run: "./gradlew test --dry-run 2>/dev/null || ./gradlew tasks 2>/dev/null | grep -q test"
      expect: "exit 0"
risk: LOW
```

---

## Verification Summary

### Agent-verifiable (A-items)

| ID | 검증 내용 | Tier | Method |
|----|----------|------|--------|
| A-1 | SKILL.md 파일 구조 | 1 | `test -f .claude/skills/atdd-*/SKILL.md` |
| A-2 | 에이전트 파일 존재 | 1 | `ls .claude/agents/atdd-*.md` |
| A-3 | YAML frontmatter 유효성 | 1 | `head -1 file | grep '^---'` |
| A-4 | Cucumber feature 생성 | 1 | `test -f src/test/resources/features/*.feature` |
| A-5 | Glue code 생성 | 1 | `grep -r '@Given' src/test/java` |
| A-6 | REST Assured 패턴 | 1 | `grep -r 'RestAssured.given()' src/test/java` |
| A-7 | Production code 생성 | 1 | `find src/main/java -name '*.java'` |
| A-8 | MySQL Testcontainers 설정 | 2 | `grep -r 'MySQLContainer' src/test/java` |
| A-9 | 테스트 실행 가능 | 2 | `./gradlew test` |

### Human-required (H-items)

| ID | 검증 내용 | 이유 |
|----|----------|------|
| H-1 | User Story → Gherkin 품질 | 사용자 의도 파악 필요 |
| H-2 | 코드 리팩토링 품질 | 코드 스타일과 설계 판단 |
| H-3 | 테스트 커버리지 적절성 | 비즈니스 임팩트 판단 |

### External Dependencies Strategy

| Dependency | 전략 |
|------------|------|
| Docker | 사용자 환경 가정 (Docker Desktop 설치) |
| MySQL 8.0+ | Testcontainers 자동 관리 |
| Java 17+ | 사용자 환경 가정 |
| Gradle/Maven | 사용자 환경 가정 |
| Spring Boot 3.2+ | 참고 프로젝트 사용 |
| Cucumber 7.14+ | 의존성 추가 필요 |
| REST Assured 5.3+ | 의존성 추가 필요 |

---

## Risk Assessment Summary

| TODO | Risk | 주의사항 |
|------|------|----------|
| TODO 1 | LOW | 문서만 생성 |
| TODO 2 | LOW | 문서 + Hook 생성 |
| TODO 3 | MEDIUM | NL parsing, Gherkin 변환 복잡도 |
| TODO 4 | MEDIUM | 테스트 구조, REST Assured, Testcontainers 설정 |
| TODO 5 | MEDIUM | Production 코드 생성 (사용자 승인 필요) |
| TODO 6 | MEDIUM | Docker 의존성 |
| TODO Final | LOW | 검증만 수행 |

**주의사항:**
- TODO 3: 자연어 처리 → Gherkin 변환은 비결정적, MEDIUM risk
- TODO 5: 코드 생성은 사용자 승인 프로세스로 MEDIUM으로 완화
