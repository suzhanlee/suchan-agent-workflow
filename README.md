# ATDD-TDD Workflow for Claude Code

**Automated Acceptance Test-Driven Development workflow for Java/Spring Boot projects**

This project provides a complete ATDD (Acceptance Test-Driven Development) workflow automation system for Claude Code, enabling developers to transform User Stories into production code through a structured TDD process.

## Overview

ATDD-TDD Workflow automates the journey from User Story to production code:

- **User Story** → **Gherkin Feature** → **Glue Code** → **Production Code** → **Tests Pass**

### Key Benefits

- **Automated Workflow**: Reduces manual steps in the ATDD process
- **Consistent Code Quality**: Enforces TDD best practices (Red-Green-Refactor)
- **Spring Boot Integration**: Optimized for Java 17+ and Spring Boot 3.2+
- **Real Database Testing**: Uses MySQL Testcontainers for integration tests
- **Type-Safe Tests**: JPA-based test data management with automatic cleanup

### Who It's For

- Java/Spring Boot developers practicing ATDD/TDD
- Teams using Cucumber for acceptance testing
- Projects requiring database-backed integration tests
- Developers using Claude Code CLI

## Quick Start

### Prerequisites

- **Java 17+**
- **Spring Boot 3.2+**
- **Docker Desktop** (for MySQL Testcontainers)
- **Gradle 7.x+** or **Maven 3.6+**
- **Claude Code CLI**

### Installation

```bash
# 1. Copy .claude/ directory to your project
cp -r .claude/ /path/to/your/project/

# 2. Add required dependencies (see below)
# 3. Verify Docker is running
docker ps

# 4. Run your first ATDD cycle
/atdd-init
```

### Add Dependencies

**Gradle (build.gradle):**
```groovy
dependencies {
    // Cucumber
    testImplementation 'io.cucumber:cucumber-java:7.14.0'
    testImplementation 'io.cucumber:cucumber-junit:7.14.0'
    testImplementation 'io.cucumber:cucumber-spring:7.14.0'

    // REST Assured
    testImplementation 'io.rest-assured:rest-assured:5.3.2'

    // Testcontainers
    testImplementation 'org.testcontainers:testcontainers:1.19.8'
    testImplementation 'org.testcontainers:mysql:1.19.8'
    testImplementation 'org.testcontainers:junit-jupiter:1.19.8'

    // Spring Boot Test
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.boot:spring-boot-testcontainers:3.2.0'
}
```

**Maven (pom.xml):**
```xml
<dependencies>
    <!-- Cucumber -->
    <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-java</artifactId>
        <version>7.14.0</version>
        <scope>test</scope>
    </dependency>

    <!-- Testcontainers -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>mysql</artifactId>
        <version>1.19.8</version>
        <scope>test</scope>
    </dependency>

    <!-- See docs/testcontainers-mysql-setup.md for complete list -->
</dependencies>
```

## Available Skills

### `/atdd-init` - User Story to Gherkin

Transforms a User Story into a Gherkin Feature file.

```
/atdd-init
```

**Input:**
- User Story (As a... I want to... So that...)
- Actor, Goal, Business Value

**Output:**
- `.feature` file in `src/test/resources/features/`

### `/atdd-generate` - Feature to Implementation

Implements the complete ATDD cycle from Gherkin to production code.

```
/atdd-generate <feature-file>
```

**Phases:**
1. **Test Phase**: Generates Glue Code (Cucumber Step Definitions)
2. **Code Phase**: Generates Production Code (Entity, Service, Controller)
3. **Refactor Phase**: Runs tests and verifies implementation

## Workflow Diagram

```
User Story
    |
    v
/atdd-init
    |
    v
┌─────────────────────────────────────────────────────┐
│              .feature File Created                   │
│  Feature: Shopping Cart Management                  │
│    Scenario: Add item to cart                       │
│      Given user has empty cart                      │
│      When user adds "Laptop"                        │
│      Then cart contains "Laptop"                    │
└─────────────────────────────────────────────────────┘
    |
    v
/atdd-generate
    |
    +--------------------------------------------------------+
    |                                                        |
    v                                                        v
┌─────────────────┐                              ┌─────────────────┐
│  Test Phase     │                              │  Code Phase     │
│  (Red)          │                              │  (Green)        │
│                 │                              │                 │
│ Step Definitions│                              │ Entity          │
│ REST Assured    │────────────────────────────>│ Repository      │
│ Testcontainers  │                              │ Service         │
│                 │                              │ Controller      │
│                 │                              │ DTOs            │
└─────────────────┘                              └─────────────────┘
    |                                                        |
    +--------------------------------------------------------+
    |
    v
┌─────────────────┐
│ Refactor Phase  │
│ (Verify)        │
│                 │
│ ./gradlew test  │
│ All tests pass  │
└─────────────────┘
```

## Example Usage

### Step 1: Define Your User Story

```
As a logged-in user
I want to add items to my shopping cart
So that I can purchase them later
```

### Step 2: Run `/atdd-init`

```bash
/atdd-init
```

**Generated Feature File** (`src/test/resources/features/shopping-cart.feature`):
```gherkin
Feature: Shopping Cart Management

  Scenario: Add item to empty cart
    Given a logged-in user with an empty shopping cart
    When the user adds "Laptop" to the cart
    Then the shopping cart should contain "Laptop"
    And the cart total should reflect the item price
```

### Step 3: Run `/atdd-generate`

```bash
/atdd-generate shopping-cart.feature
```

**Phase 1: Test (Red)**
- Generates `ShoppingCartSteps.java` with Cucumber annotations
- Sets up REST Assured for API testing
- Configures MySQL Testcontainers

```java
@Given("a logged-in user with an empty shopping cart")
public void a_logged_in_user_with_an_empty_shopping_cart() {
    cart = new ShoppingCart();
    assertThat(cart.isEmpty()).isTrue();
}

@When("the user adds {string} to the cart")
public void the_user_adds_to_the_cart(String productName) {
    cart.addProduct(new Product(productName, 10000));
}

@Then("the shopping cart should contain {string}")
public void the_shopping_cart_should_contain(String productName) {
    assertThat(cart.contains(productName)).isTrue();
}
```

**Phase 2: Code (Green)**
- Generates `ShoppingCart.java` entity
- Generates `ProductRepository.java`
- Generates `ShoppingCartService.java`
- Generates `ShoppingCartController.java`

```java
@Service
public class ShoppingCartService {
    public void addItem(Product product) {
        cart.getProducts().add(product);
    }
}

@RestController
@RequestMapping("/api/cart")
public class ShoppingCartController {
    @PostMapping("/items")
    public ResponseEntity<Void> addItem(@RequestBody AddItemRequest request) {
        service.addItem(request.getProductId());
        return ResponseEntity.ok().build();
    }
}
```

**Phase 3: Refactor (Verify)**
- Runs `./gradlew test`
- All Cucumber scenarios pass
- Ready for production

## Requirements

### Java & Spring Boot

- **Java 17+** (Spring Boot 3.x requires Jakarta EE)
- **Spring Boot 3.2+**
- **Spring Data JPA**
- **Spring Web**

### Database

- **MySQL 8.0** (via Testcontainers)
- **Docker Desktop** running

### Build Tool

- **Gradle 7.x+** or **Maven 3.6+**

### Testing Libraries

- Cucumber 7.14+
- REST Assured 5.3+
- Testcontainers 1.19.8+
- AssertJ (included with Spring Boot Test)

## Directory Structure

```
.claude/
├── settings.json           # Main configuration (hooks, permissions)
├── skills/
│   ├── atdd-init/
│   │   └── SKILL.md       # User Story to Gherkin conversion
│   └── atdd-generate/
│       └── SKILL.md       # Gherkin to Implementation workflow
├── agents/
│   ├── atdd-criteria-generator.md  # Gherkin generation logic
│   ├── atdd-test-writer.md         # Glue code generation
│   └── atdd-code-writer.md         # Production code generation
└── scripts/
    └── atdd-hook.sh       # State machine + colored output

docs/
├── ARCHITECTURE.md        # Technical architecture documentation
└── testcontainers-mysql-setup.md  # Testcontainers setup guide

src/
├── test/
│   ├── resources/
│   │   └── features/      # Generated .feature files
│   └── java/
│       └── {package}/glue/ # Generated Step Definitions
└── main/
    └── java/
        └── {package}/     # Generated production code
            ├── domain/    # Entities
            ├── repository/ # Repositories
            ├── service/   # Services
            └── controller/# Controllers
```

## Configuration

### Hook System

The workflow uses hooks for phase transitions:

```json
{
  "hooks": {
    "atdd-stop": {
      "description": "ATDD phase transition automation",
      "command": "bash .claude/scripts/atdd-hook.sh",
      "trigger": "afterSkill"
    }
  },
  "skills": {
    "atdd-generate": {
      "hooks": {
        "onStop": "atdd-stop"
      }
    }
  }
}
```

### State Management

ATDD state is tracked in `.atdd-state.json`:

```json
{
  "current_phase": "code",
  "feature_file": "src/test/resources/features/shopping-cart.feature",
  "status": "completed",
  "generated_files": [
    "src/test/java/com/example/glue/ShoppingCartSteps.java",
    "src/main/java/com/example/domain/ShoppingCart.java"
  ],
  "test_results": {
    "last_run": "2026-02-04T21:30:00Z",
    "status": "passed",
    "scenarios": {
      "total": 5,
      "passed": 5,
      "failed": 0
    }
  }
}
```

## Best Practices

### 1. Write Clear User Stories

```
As a <role>
I want to <feature>
So that <business value>
```

### 2. Review Generated Code

Always review generated code before committing. The AI generates working code, but you should verify:
- Business logic correctness
- Error handling
- Edge cases
- Code style consistency

### 3. Use Testcontainers Reuse

Enable container reuse for faster tests:

```bash
# ~/.testcontainers.properties
testcontainers.reuse.enable=true
```

```java
MySQLContainer<?> container = new MySQLContainer<>("mysql:8.0")
    .withReuse(true);
```

### 4. Run Tests Frequently

```bash
# Run all Cucumber tests
./gradlew test --tests "*Cucumber*"

# Run specific feature
./gradlew test --tests "*ShoppingCart*"

# Run with verbose output
./gradlew test --info
```

## Troubleshooting

### Docker Not Running

**Error:** `Container startup failed`

**Solution:** Start Docker Desktop
```bash
docker ps
```

### Tests Fail to Connect to Database

**Error:** `Cannot open connection`

**Solution:** Verify Testcontainers configuration
```java
@DynamicPropertySource
static void configureProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", mysql::getJdbcUrl);
}
```

### Port Conflicts

**Error:** `Port already in use`

**Solution:** Use `RANDOM_PORT`
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)

@LocalServerPort
private int port;
```

## Additional Resources

- [Testcontainers MySQL Setup Guide](docs/testcontainers-mysql-setup.md) - Comprehensive Testcontainers configuration
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Technical architecture and design decisions
- [Cucumber Documentation](https://cucumber.io/docs/cucumber/)
- [Testcontainers Documentation](https://www.testcontainers.org/)
- [Spring Boot Testing](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing)

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see LICENSE file for details

---

**Last Updated:** 2026-02-04

**Version:** 1.0.0

**Compatible with:** Claude Code CLI, Java 17+, Spring Boot 3.2+
