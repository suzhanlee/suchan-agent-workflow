# MySQL Testcontainers Setup Guide

This guide provides comprehensive instructions for setting up MySQL Testcontainers in your Spring Boot project for integration testing.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Dependencies](#dependencies)
- [Basic Configuration](#basic-configuration)
- [Advanced Configuration](#advanced-configuration)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

[Testcontainers](https://www.testcontainers.org/) is a Java library that supports JUnit tests, providing lightweight, throwaway instances of common databases, Selenium web browsers, or anything else that can run in a Docker container.

### Benefits

- **Real Database Testing**: Test against actual MySQL instead of H2 in-memory database
- **Isolation**: Each test gets a fresh container
- **Performance**: Containers are reused across tests with singleton pattern
- **CI/CD Ready**: Works in any environment with Docker installed
- **Spring Boot Integration**: Seamless integration with Spring's test context

---

## Prerequisites

### Required Software

1. **Docker Desktop** (or Docker Engine)
   - [Download for Windows/Mac](https://www.docker.com/products/docker-desktop/)
   - [Linux installation guide](https://docs.docker.com/engine/install/)
   - Verify installation: `docker --version`

2. **Java 17+** (Spring Boot 3.x requirement)

3. **Gradle 7.x+** or **Maven 3.6+**

### Verify Docker Setup

```bash
# Verify Docker is running
docker ps

# Test MySQL container startup
docker run --rm mysql:8.0 echo "MySQL container works"
```

---

## Dependencies

### Gradle (build.gradle)

#### Gradle Groovy DSL

```groovy
dependencies {
    // Testcontainers core
    testImplementation 'org.testcontainers:testcontainers:1.19.8'

    // Testcontainers MySQL module
    testImplementation 'org.testcontainers:mysql:1.19.8'

    // Testcontainers JUnit 5 integration
    testImplementation 'org.testcontainers:junit-jupiter:1.19.8'

    // Spring Boot Test (already included in spring-boot-starter-test)
    testImplementation 'org.springframework.boot:spring-boot-starter-test'

    // Optional: Spring Boot Testcontainers (Spring Boot 3.1+)
    testImplementation 'org.springframework.boot:spring-boot-testcontainers:3.2.0'
}
```

#### Gradle Kotlin DSL

```kotlin
dependencies {
    // Testcontainers core
    testImplementation("org.testcontainers:testcontainers:1.19.8")

    // Testcontainers MySQL module
    testImplementation("org.testcontainers:mysql:1.19.8")

    // Testcontainers JUnit 5 integration
    testImplementation("org.testcontainers:junit-jupiter:1.19.8")

    // Spring Boot Test
    testImplementation("org.springframework.boot:spring-boot-starter-test")

    // Optional: Spring Boot Testcontainers (Spring Boot 3.1+)
    testImplementation("org.springframework.boot:spring-boot-testcontainers:3.2.0")
}
```

### Maven (pom.xml)

```xml
<dependencies>
    <!-- Testcontainers core -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>testcontainers</artifactId>
        <version>1.19.8</version>
        <scope>test</scope>
    </dependency>

    <!-- Testcontainers MySQL module -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>mysql</artifactId>
        <version>1.19.8</version>
        <scope>test</scope>
    </dependency>

    <!-- Testcontainers JUnit 5 integration -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>1.19.8</version>
        <scope>test</scope>
    </dependency>

    <!-- Spring Boot Test -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- Optional: Spring Boot Testcontainers (Spring Boot 3.1+) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-testcontainers</artifactId>
        <version>3.2.0</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Version Management

**For Gradle (using Version Catalog):**

```toml
# gradle/libs.versions.toml
[versions]
testcontainers = "1.19.8"

[libraries]
testcontainers = { module = "org.testcontainers:testcontainers", version.ref = "testcontainers" }
testcontainers-mysql = { module = "org.testcontainers:mysql", version.ref = "testcontainers" }
testcontainers-junit-jupiter = { module = "org.testcontainers:junit-jupiter", version.ref = "testcontainers" }
```

**For Maven (using properties):**

```xml
<properties>
    <testcontainers.version>1.19.8</testcontainers.version>
</properties>
```

---

## Basic Configuration

### 1. Application Test Properties

Create `src/test/resources/application-test.yml`:

```yaml
spring:
  datasource:
    url: ${TEST_DB_URL}
    username: ${TEST_DB_USERNAME}
    password: ${TEST_DB_PASSWORD}
    driver-class-name: com.mysql.cj.jdbc.Driver

  jpa:
    hibernate:
      ddl-auto: create-drop
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQLDialect
        format_sql: true
    show-sql: true

logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE
```

### 2. Base Test Class

Create a reusable base test class:

```java
package com.example.common;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
public abstract class BaseMySQLTest {

    @Container
    static final MySQLContainer<?> mysqlContainer = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("testuser")
            .withPassword("testpass")
            .withReuse(true); // Enable container reuse

    @DynamicPropertySource
    static void setProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysqlContainer::getJdbcUrl);
        registry.add("spring.datasource.username", mysqlContainer::getUsername);
        registry.add("spring.datasource.password", mysqlContainer::getPassword);
    }
}
```

### 3. Simple Test Example

```java
package com.example.repository;

import com.example.common.BaseMySQLTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class UserRepositoryTest extends BaseMySQLTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void shouldSaveUser() {
        // Given
        User user = new User("test@example.com", "John Doe");

        // When
        User savedUser = userRepository.save(user);

        // Then
        assertThat(savedUser.getId()).isNotNull();
        assertThat(savedUser.getEmail()).isEqualTo("test@example.com");
    }
}
```

---

## Advanced Configuration

### 1. Singleton Pattern for Performance

For optimal performance, use a singleton container that runs once and is reused across all tests:

#### Option A: Singleton Container Class

```java
package com.example.config;

import org.testcontainers.containers.MySQLContainer;

public class MySQLTestContainer {

    private static final MySQLContainer<?> container;

    static {
        container = new MySQLContainer<>("mysql:8.0")
                .withDatabaseName("testdb")
                .withUsername("testuser")
                .withPassword("testpass")
                .withReuse(true); // Critical for performance

        container.start();
    }

    public static MySQLContainer<?> getContainer() {
        return container;
    }

    private MySQLTestContainer() {
        // Private constructor to prevent instantiation
    }
}
```

#### Option B: Spring Boot 3.1+ @ServiceConnection

```java
package com.example.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.MySQLContainer;

@TestConfiguration(proxyBeanMethods = false)
public class TestContainerConfiguration {

    @Bean
    @ServiceConnection
    public MySQLContainer<?> mysqlContainer() {
        return new MySQLContainer<>("mysql:8.0")
                .withDatabaseName("testdb")
                .withUsername("testuser")
                .withPassword("testpass")
                .withReuse(true);
    }
}
```

#### Usage with Singleton Pattern

```java
package com.example.config;

import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;
import org.testcontainers.containers.MySQLContainer;

public class MySQLContainerExtension implements BeforeAllCallback {

    private static MySQLContainer<?> container;

    @Override
    public void beforeAll(ExtensionContext context) {
        if (container == null) {
            container = new MySQLContainer<>("mysql:8.0")
                    .withDatabaseName("testdb")
                    .withUsername("testuser")
                    .withPassword("testpass")
                    .withReuse(true);

            container.start();
        }
    }

    public static String getJdbcUrl() {
        return container.getJdbcUrl();
    }

    public static String getUsername() {
        return container.getUsername();
    }

    public static String getPassword() {
        return container.getPassword();
    }
}
```

Register the extension:

```java
package com.example.common;

import com.example.config.MySQLContainerExtension;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

@SpringBootTest
@ExtendWith(MySQLContainerExtension.class)
public abstract class BaseMySQLSingletonTest {

    @DynamicPropertySource
    static void setProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MySQLContainerExtension::getJdbcUrl);
        registry.add("spring.datasource.username", MySQLContainerExtension::getUsername);
        registry.add("spring.datasource.password", MySQLContainerExtension::getPassword);
    }
}
```

### 2. @Testcontainers Annotation Usage

The `@Testcontainers` annotation manages container lifecycle:

```java
package com.example.integration;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Testcontainers
@TestInstance(TestInstance.Lifecycle.PER_CLASS) // Optional: control lifecycle
class UserServiceIntegrationTest {

    // Container created once for all tests in this class
    @Container
    private final MySQLContainer<?> mysqlContainer = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("testuser")
            .withPassword("testpass");

    @DynamicPropertySource
    static void setProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysqlContainer::getJdbcUrl);
        registry.add("spring.datasource.username", mysqlContainer::getUsername);
        registry.add("spring.datasource.password", mysqlContainer::getPassword);
    }

    @Autowired
    private UserService userService;

    @Test
    void shouldCreateUser() {
        // Test implementation
    }

    @Test
    void shouldFindUserById() {
        // Test implementation
    }
}
```

### 3. MySQLContainer Bean Setup

#### Manual Bean Configuration (Spring Boot < 3.1)

```java
package com.example.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.testcontainers.containers.MySQLContainer;

@TestConfiguration
public class MySQLTestConfig {

    @Bean
    public MySQLContainer<?> mysqlContainer(DynamicPropertyRegistry registry) {
        MySQLContainer<?> mysqlContainer = new MySQLContainer<>("mysql:8.0")
                .withDatabaseName("testdb")
                .withUsername("testuser")
                .withPassword("testpass")
                .withReuse(true);

        mysqlContainer.start();

        // Register dynamic properties
        registry.add("spring.datasource.url", mysqlContainer::getJdbcUrl);
        registry.add("spring.datasource.username", mysqlContainer::getUsername);
        registry.add("spring.datasource.password", mysqlContainer::getPassword);

        return mysqlContainer;
    }
}
```

#### Import the Configuration

```java
package com.example.integration;

import com.example.config.MySQLTestConfig;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;

@SpringBootTest
@Import(MySQLTestConfig.class)
class UserServiceIntegrationTest {
    // Tests...
}
```

### 4. Custom MySQL Configuration

```java
package com.example.config;

import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.utility.DockerImageName;

public class CustomMySQLContainer extends MySQLContainer<CustomMySQLContainer> {

    private static final String IMAGE_VERSION = "mysql:8.0";
    private static CustomMySQLContainer container;

    private CustomMySQLContainer() {
        super(DockerImageName.parse(IMAGE_VERSION).asCompatibleSubstituteFor("mysql"));
    }

    public static CustomMySQLContainer getInstance() {
        if (container == null) {
            container = new CustomMySQLContainer()
                    .withDatabaseName("testdb")
                    .withUsername("testuser")
                    .withPassword("testpass")
                    .withEnv("MYSQL_ROOT_HOST", "%") // Allow remote connections
                    .withCommand(
                            "--character-set-server=utf8mb4",
                            "--collation-server=utf8mb4_unicode_ci",
                            "--default-authentication-plugin=mysql_native_password"
                    )
                    .withReuse(true);
        }
        return container;
    }

    @Override
    public void start() {
        super.start();
        System.out.println("MySQL container started at: " + getJdbcUrl());
    }

    @Override
    public void stop() {
        // Override to prevent container from stopping between tests
        // Container will be stopped when JVM exits
    }
}
```

### 5. Multiple Test Configurations

```java
package com.example.config;

import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;

@DataJpaTest
@ExtendWith(MySQLContainerExtension.class)
public abstract class BaseRepositoryTest {

    @DynamicPropertySource
    static void setProperties(DynamicPropertyRegistry registry) {
        MySQLContainer<?> container = MySQLTestContainer.getContainer();

        registry.add("spring.datasource.url", container::getJdbcUrl);
        registry.add("spring.datasource.username", container::getUsername);
        registry.add("spring.datasource.password", container::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
    }
}
```

---

## Usage Examples

### Example 1: Repository Test

```java
package com.example.repository;

import com.example.common.BaseMySQLTest;
import com.example.entity.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class UserRepositoryTest extends BaseMySQLTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("Should save and find user by email")
    void shouldSaveAndFindUserByEmail() {
        // Given
        User user = new User("john@example.com", "John Doe");
        userRepository.save(user);

        // When
        Optional<User> found = userRepository.findByEmail("john@example.com");

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("John Doe");
    }

    @Test
    @DisplayName("Should return empty when user not found")
    void shouldReturnEmptyWhenUserNotFound() {
        // When
        Optional<User> found = userRepository.findByEmail("nonexistent@example.com");

        // Then
        assertThat(found).isEmpty();
    }
}
```

### Example 2: Service Integration Test

```java
package com.example.service;

import com.example.common.BaseMySQLTest;
import com.example.entity.User;
import com.example.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
class UserServiceIntegrationTest extends BaseMySQLTest {

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @AfterEach
    void cleanup() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("Should create user successfully")
    void shouldCreateUserSuccessfully() {
        // When
        User user = userService.createUser("test@example.com", "Test User");

        // Then
        assertThat(user.getId()).isNotNull();
        assertThat(user.getEmail()).isEqualTo("test@example.com");

        // Verify in database
        User savedUser = userRepository.findById(user.getId()).orElseThrow();
        assertThat(savedUser.getName()).isEqualTo("Test User");
    }

    @Test
    @DisplayName("Should throw exception when creating duplicate user")
    void shouldThrowExceptionWhenCreatingDuplicateUser() {
        // Given
        userService.createUser("test@example.com", "Test User");

        // When & Then
        assertThatThrownBy(() ->
            userService.createUser("test@example.com", "Another User")
        ).isInstanceOf(IllegalArgumentException.class)
         .hasMessageContaining("Email already exists");
    }
}
```

### Example 3: Controller Integration Test

```java
package com.example.controller;

import com.example.common.BaseMySQLTest;
import com.example.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class UserControllerIntegrationTest extends BaseMySQLTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @AfterEach
    void cleanup() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("Should create user via REST API")
    void shouldCreateUserViaRestApi() throws Exception {
        // Given
        String requestBody = """
            {
                "email": "test@example.com",
                "name": "Test User"
            }
            """;

        // When & Then
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value("test@example.com"))
                .andExpect(jsonPath("$.name").value("Test User"))
                .andExpect(jsonPath("$.id").exists());
    }
}
```

### Example 4: Using @ParameterizedTest

```java
package com.example.repository;

import com.example.common.BaseMySQLTest;
import com.example.entity.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

class UserRepositoryParameterizedTest extends BaseMySQLTest {

    @Autowired
    private UserRepository userRepository;

    @ParameterizedTest
    @ValueSource(strings = {
        "user1@example.com",
        "user2@example.com",
        "user3@example.com"
    })
    @DisplayName("Should save users with different emails")
    void shouldSaveUsersWithDifferentEmails(String email) {
        // Given
        User user = new User(email, "Test User");

        // When
        User savedUser = userRepository.save(user);

        // Then
        assertThat(savedUser.getEmail()).isEqualTo(email);
        assertThat(userRepository.findByEmail(email)).isPresent();
    }
}
```

---

## Best Practices

### 1. Container Reuse

Always enable container reuse for better performance:

```java
MySQLContainer<?> container = new MySQLContainer<>("mysql:8.0")
    .withReuse(true);
```

Set environment variable for all tests:

```bash
# ~/.testcontainers.properties
testcontainers.reuse.enable=true
```

### 2. Test Isolation

Clean database state between tests:

```java
@AfterEach
void cleanup() {
    userRepository.deleteAll();
}

// Or use @Transactional for automatic rollback
@Transactional
@Test
void testWithAutoRollback() {
    // Changes will be rolled back after test
}
```

### 3. Use Appropriate MySQL Version

Match your production MySQL version:

```java
new MySQLContainer<>("mysql:8.0")     // Latest 8.0.x
new MySQLContainer<>("mysql:8.0.35")  // Specific version
new MySQLContainer<>("mysql:5.7")     // Legacy version
```

### 4. Optimize Container Configuration

```java
MySQLContainer<?> container = new MySQLContainer<>("mysql:8.0")
    .withDatabaseName("testdb")
    .withUsername("testuser")
    .withPassword("testpass")
    .withCommand(
        "--character-set-server=utf8mb4",
        "--collation-server=utf8mb4_unicode_ci",
        "--max-connections=200",
        "--default-authentication-plugin=mysql_native_password"
    );
```

### 5. Profile-Specific Configuration

```java
@SpringBootTest
@ActiveProfiles("test")
class MyTest { }

# src/test/resources/application-test.yml
spring:
  datasource:
    url: ${TEST_DB_URL}
    username: ${TEST_DB_USERNAME}
    password: ${TEST_DB_PASSWORD}
```

### 6. Use @DataJpaTest for Repository Tests

```java
@DataJpaTest
class UserRepositoryTest extends BaseMySQLTest {
    // Only JPA components are loaded (faster than @SpringBootTest)
}
```

### 7. Disable unnecessary features in tests

```yaml
# src/test/resources/application-test.yml
spring:
  jpa:
    show-sql: false  # Disable in production tests
    properties:
      hibernate:
        format_sql: false

logging:
  level:
    com.example: DEBUG  # Only your package
    org.hibernate: INFO  # Reduce noise
```

### 8. Use Test Slices

- `@DataJpaTest` for repository tests
- `@WebMvcTest` for controller tests (no database)
- `@JsonTest` for JSON serialization
- `@SpringBootTest` only when needed

---

## Troubleshooting

### Issue 1: Docker Daemon Not Running

**Error:**
```
org.testcontainers.containers.ContainerLaunchException:
Container startup failed
```

**Solution:**
```bash
# Start Docker Desktop
# On Windows: Start Docker Desktop from Start Menu
# On Mac: Start Docker Desktop from Applications
# On Linux: sudo systemctl start docker

# Verify
docker ps
```

### Issue 2: Container Reuse Not Working

**Error:**
Containers starting for every test

**Solution:**
```bash
# Create ~/.testcontainers.properties
echo "testcontainers.reuse.enable=true" > ~/.testcontainers.properties

# In code, ensure withReuse(true) is called
container.withReuse(true);
```

### Issue 3: Connection Timeout

**Error:**
```
Could not create connection to database server
```

**Solution:**
```java
MySQLContainer<?> container = new MySQLContainer<>("mysql:8.0")
    .withStartupTimeoutSeconds(120)  // Increase timeout
    .withConnectTimeoutSeconds(60);
```

### Issue 4: Port Already in Use

**Error:**
```
Port 3306 is already allocated
```

**Solution:**
Testcontainers automatically assigns random ports. If you have local MySQL running:
```bash
# Stop local MySQL during tests
# Windows: net stop MySQL
# Mac: brew services stop mysql
# Linux: sudo systemctl stop mysql
```

### Issue 5: Unsupported MySQL Version

**Error:**
```
Exception: Unsupported MySQL version
```

**Solution:**
Use compatible MySQL image:
```java
new MySQLContainer<>("mysql:8.0")  // Use official MySQL images
```

### Issue 6: Insufficient Docker Resources

**Error:**
```
Exception: Cannot allocate memory
```

**Solution:**
Increase Docker resources in Docker Desktop:
- Settings → Resources → Memory: 4GB+
- Settings → Resources → Swap: 2GB+

### Issue 7: Slow Test Execution

**Solutions:**

1. Enable container reuse
2. Use singleton pattern
3. Reduce test logging
4. Use test slices (@DataJpaTest vs @SpringBootTest)
5. Parallel test execution:

```java
// gradle.properties
org.gradle.parallel=true
org.gradle.jvmargs=-Xmx2048m
```

### Issue 8: Timezone Issues

**Solution:**
```java
MySQLContainer<?> container = new MySQLContainer<>("mysql:8.0")
    .withCommand("SET GLOBAL time_zone = 'UTC'");
```

---

## Additional Resources

### Official Documentation
- [Testcontainers Official Docs](https://www.testcontainers.org/)
- [Testcontainers MySQL Module](https://www.testcontainers.org/modules/databases/mysql/)
- [Spring Boot Testcontainers](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing.testcontainers)

### Community
- [Testcontainers GitHub](https://github.com/testcontainers/testcontainers-java)
- [Testcontainers Discussion](https://github.com/testcontainers/testcontainers-java/discussions)

### Related Guides
- [PostgreSQL Testcontainers Setup](./testcontainers-postgres-setup.md)
- [Integration Testing Best Practices](./integration-testing-best-practices.md)

---

## Quick Start Checklist

- [ ] Docker Desktop installed and running
- [ ] Testcontainers dependencies added to build.gradle/pom.xml
- [ ] Base test class created with MySQLContainer configuration
- [ ] application-test.yml configured with dynamic properties
- [ ] Container reuse enabled
- [ ] First test written and passing
- [ ] CI/CD pipeline configured with Docker support

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-04 | Initial version with MySQL Testcontainers setup guide |

---

**Last Updated:** 2026-02-04

**Testcontainers Version:** 1.19.8

**Spring Boot Version:** 3.2.0

**MySQL Version:** 8.0
