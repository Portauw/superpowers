# Universal Software Design Principles

Reference guide for DDD, Clean Architecture, SOLID, and Clean Code principles. Use this as a checklist when reviewing code.

## 1. DDD Strategic Patterns

### Bounded Contexts

**What:** Self-contained subsystems with their own domain model and ubiquitous language.

**Identification questions:**
- Does this concept mean the same thing in both contexts?
- Would changing this logic affect other contexts?
- Do teams own different parts of this model?

**Red flags:**
- ❌ One model trying to serve multiple contexts (e.g., "User" shared across auth, billing, and content)
- ❌ Shared database tables across contexts
- ❌ Direct imports between contexts without translation layer
- ❌ Contexts that can't be deployed independently

### Ubiquitous Language

**What:** Each bounded context has its own vocabulary. Terms in code match terms domain experts use.

**Rules:**
- Domain layer uses ONLY domain terms
- Same word can mean different things in different contexts
- Code names match spoken language exactly

**Red flags:**
- ❌ Generic names in domain layer: `data`, `info`, `item`, `record`, `manager`, `handler`
- ❌ Technical names leaking into domain: `DTO`, `DAO`, `response`, `request`
- ❌ Domain experts say "customer" but code says "user"

### Context Mapping

**Relationship types:**
- **Shared Kernel:** Two contexts share a small common model (use sparingly, creates coupling)
- **Anti-Corruption Layer (ACL):** Translate external models to prevent pollution of your domain
- **Customer/Supplier:** Downstream context depends on upstream, with negotiation
- **Conformist:** Downstream accepts upstream model as-is (no translation)
- **Open Host Service:** Context provides well-defined API for others
- **Published Language:** Shared interchange format (JSON schema, protocol buffers)

### Anti-Corruption Layers

**When needed:**
- Integrating with legacy systems
- Calling external APIs
- Consuming third-party services
- Working with frameworks that want to dictate your model

**How:**
- Translate at the boundary (adapter layer)
- NEVER let external models leak into domain
- External types stay in infrastructure layer

**Example:**
```typescript
// ❌ BAD: External model leaked into domain
class Order {
  stripePaymentIntent: Stripe.PaymentIntent; // External type!
}

// ✅ GOOD: ACL translates at boundary
class Order {
  payment: Payment; // Domain type
}

// Infrastructure layer
class StripePaymentAdapter {
  toDomain(intent: Stripe.PaymentIntent): Payment { /* translate */ }
  toStripe(payment: Payment): Stripe.PaymentIntent { /* translate */ }
}
```

## 2. DDD Tactical Patterns

### Aggregates

**Rules:**
| Rule | Why |
|------|-----|
| Consistency boundary | All invariants enforced within one transaction |
| Root entity owns the aggregate | External access only through root |
| One transaction per aggregate | If you need two, wrong boundary |
| Reference other aggregates by ID only | No direct object references across aggregates |

**Red flags:**
- ❌ Modifying multiple aggregates in one transaction
- ❌ Loading full aggregate just to get one field (query model instead)
- ❌ Aggregate holding references to other aggregate instances

### Entities

**Characteristics:**
- Have identity (ID, key) that survives state changes
- Lifecycle (created, modified, deleted)
- Mutable state
- Equality by identity, not by value

**Example:**
```typescript
// Entity - identity matters
class Order {
  constructor(public id: OrderId, public items: OrderItem[]) {}

  equals(other: Order): boolean {
    return this.id.equals(other.id); // Compare by ID
  }
}
```

### Value Objects

**Characteristics:**
- Equality by value (not reference)
- Immutable (no setters)
- No identity
- Self-validating

**Examples:** Money, Address, DateRange, Email, PhoneNumber

**Pattern:**
```typescript
// Value Object
class Money {
  private constructor(
    public readonly amount: number,
    public readonly currency: Currency
  ) {
    if (amount < 0) throw new Error("Amount cannot be negative");
  }

  static create(amount: number, currency: Currency): Money {
    return new Money(amount, currency);
  }

  add(other: Money): Money {
    if (!this.currency.equals(other.currency)) {
      throw new Error("Cannot add different currencies");
    }
    return new Money(this.amount + other.amount, this.currency);
  }

  equals(other: Money): boolean {
    return this.amount === other.amount &&
           this.currency.equals(other.currency); // Compare by value
  }
}
```

**Red flags:**
- ❌ Value object with setters
- ❌ Value object with an ID
- ❌ Primitive obsession (using `string` instead of `Email` value object)

### Domain Events

**What:** Record that something happened in the domain (past tense).

**Uses:**
- Cross-context communication (eventual consistency)
- Audit trail
- Triggering side effects without coupling

**Naming:** Past tense verbs: `OrderPlaced`, `PaymentReceived`, `CustomerRegistered`

**Pattern:**
```typescript
class OrderPlaced {
  constructor(
    public readonly orderId: OrderId,
    public readonly customerId: CustomerId,
    public readonly occurredAt: Date
  ) {}
}

// Aggregate emits event
class Order {
  place(): void {
    // ... business logic ...
    this.addEvent(new OrderPlaced(this.id, this.customerId, new Date()));
  }
}
```

**Red flags:**
- ❌ Present tense names: `PlaceOrder` (that's a command)
- ❌ Events with behavior/methods (events are data)
- ❌ Mutable events

### Repositories

**What:** Abstraction over data access with collection-like interface.

**Rules:**
- One repository per aggregate root
- Interface lives in domain layer
- Implementation lives in infrastructure layer
- Returns domain objects, not database types

**Pattern:**
```typescript
// Domain layer
interface OrderRepository {
  add(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
  findByCustomer(customerId: CustomerId): Promise<Order[]>;
}

// Infrastructure layer
class PostgresOrderRepository implements OrderRepository {
  async add(order: Order): Promise<void> {
    // SQL implementation
  }
}
```

**Red flags:**
- ❌ Repository returning SQL result sets or HTTP responses
- ❌ Repository doing business logic (that's domain service territory)
- ❌ Multiple repositories for parts of one aggregate
- ❌ Repository with update methods for every field (just save the aggregate)

### Domain Services

**When:** Stateless operations that don't naturally belong to a single entity/value object.

**Examples:**
- Money exchange (involves two currencies)
- Transfer between accounts (involves two accounts)
- Pricing calculation (involves product, customer tier, promotions)

**Pattern:**
```typescript
class MoneyExchangeService {
  constructor(private exchangeRates: ExchangeRateProvider) {}

  exchange(money: Money, targetCurrency: Currency): Money {
    const rate = this.exchangeRates.getRate(money.currency, targetCurrency);
    return Money.create(money.amount * rate, targetCurrency);
  }
}
```

**Red flags:**
- ❌ Service doing CRUD operations (that's a repository)
- ❌ Service with mutable state (should be stateless)
- ❌ Service named `*Manager` or `*Helper` (usually means unclear responsibility)

## 3. Clean Architecture

### The Dependency Rule

**CRITICAL:** Dependencies point inward ONLY.

```
Infrastructure → Application → Domain
     (outer)         (middle)    (inner)
```

**NEVER:** Domain imports from infrastructure or application.

### Layer Responsibilities

| Layer | Responsibilities | Imports | NO imports from |
|-------|-----------------|---------|-----------------|
| **Domain** | Pure business logic, entities, value objects, domain events, interfaces | Nothing (or other domain) | Infrastructure, Application, Frameworks |
| **Application** | Use cases, orchestration, transaction boundaries | Domain only | Infrastructure, Frameworks |
| **Infrastructure** | Database, APIs, UI, frameworks | Domain (interfaces only), Application | N/A (outermost layer) |

### Ports & Adapters

**Pattern:**
1. Domain defines interfaces (ports)
2. Infrastructure provides implementations (adapters)
3. Application uses interfaces, infrastructure injects implementations

**Example:**
```typescript
// Domain layer - defines port
interface OrderRepository {
  save(order: Order): Promise<void>;
}

// Application layer - uses port
class PlaceOrderUseCase {
  constructor(private orders: OrderRepository) {} // Depends on interface

  async execute(command: PlaceOrderCommand): Promise<void> {
    const order = Order.create(/* ... */);
    await this.orders.save(order);
  }
}

// Infrastructure layer - provides adapter
class PostgresOrderRepository implements OrderRepository {
  async save(order: Order): Promise<void> {
    // Postgres-specific implementation
  }
}
```

### Red Flags

- ❌ Framework annotations in domain entities (`@Entity`, `@Column`, `@Injectable`)
- ❌ Database types in domain (`UUID` from postgres, `ObjectId` from MongoDB)
- ❌ HTTP concerns in application layer (`Request`, `Response`, status codes)
- ❌ Domain importing from infrastructure (`import { db } from '../infrastructure'`)
- ❌ Domain layer depending on framework (NestJS, Express, Django)

## 4. SOLID Principles

### Single Responsibility Principle (SRP)

**Rule:** One reason to change.

**Check:** If requirement X changes, does this class need to change? If requirement Y (unrelated) changes, does it also need to change? If yes to both → SRP violation.

**Red flags:**
- ❌ Class that changes when UI changes AND when business rules change
- ❌ Class with multiple unrelated methods (persistence + validation + formatting)
- ❌ Class named with "And" (`UserAndOrderManager`)

### Open/Closed Principle (OCP)

**Rule:** Open for extension, closed for modification.

**Prefer:** Composition, strategy pattern, polymorphism over switch/if-else chains.

**Example:**
```typescript
// ❌ BAD: Need to modify function to add payment types
function processPayment(type: string) {
  if (type === 'credit') { /* ... */ }
  else if (type === 'paypal') { /* ... */ }
  // Need to edit this function for new payment types
}

// ✅ GOOD: New payment types don't modify existing code
interface PaymentProcessor {
  process(amount: Money): Promise<void>;
}

class CreditCardProcessor implements PaymentProcessor { /* ... */ }
class PayPalProcessor implements PaymentProcessor { /* ... */ }
```

### Liskov Substitution Principle (LSP)

**Rule:** Subtypes must be substitutable for their base types without breaking correctness.

**Red flags:**
- ❌ Subclass throwing "not supported" exceptions
- ❌ Subclass with stricter preconditions (requires more than parent)
- ❌ Subclass with weaker postconditions (guarantees less than parent)
- ❌ Subclass that removes/disables parent behavior

**Example:**
```typescript
// ❌ BAD: Rectangle-Square problem
class Rectangle {
  setWidth(w: number) { this.width = w; }
  setHeight(h: number) { this.height = h; }
}

class Square extends Rectangle {
  setWidth(w: number) {
    this.width = w;
    this.height = w; // Violates LSP - unexpected side effect
  }
}
```

### Interface Segregation Principle (ISP)

**Rule:** Many small, focused interfaces > one large interface.

**Check:** Do most implementers only use 2-3 methods of a 10-method interface? If yes → split the interface.

**Example:**
```typescript
// ❌ BAD: Fat interface
interface Worker {
  work(): void;
  eat(): void;
  sleep(): void;
  reportToManager(): void;
}

class Robot implements Worker {
  work() { /* ... */ }
  eat() { throw new Error("Robots don't eat"); } // Forced to implement irrelevant methods
  sleep() { throw new Error("Robots don't sleep"); }
  reportToManager() { throw new Error("Robots don't report"); }
}

// ✅ GOOD: Segregated interfaces
interface Workable { work(): void; }
interface Feedable { eat(): void; }
interface Sleepable { sleep(): void; }

class Robot implements Workable {
  work() { /* ... */ }
}
```

### Dependency Inversion Principle (DIP)

**Rule:** High-level modules should not depend on low-level modules. Both should depend on abstractions.

**Pattern:** Depend on interfaces, not concrete classes.

**Red flags:**
- ❌ Use case directly instantiating database connection
- ❌ Use case importing from infrastructure layer
- ❌ `new DatabaseClient()` in application code
- ❌ Hard-coded dependencies

**Example:**
```typescript
// ❌ BAD: High-level depends on low-level
class PlaceOrderUseCase {
  async execute(command: PlaceOrderCommand) {
    const db = new PostgresClient(); // Direct dependency on infrastructure
    // ...
  }
}

// ✅ GOOD: Both depend on abstraction
interface OrderRepository { /* ... */ }

class PlaceOrderUseCase {
  constructor(private orders: OrderRepository) {} // Depends on abstraction
}

class PostgresOrderRepository implements OrderRepository { /* ... */ }
```

## 5. Clean Code

### Naming

**Rules:**
- Intention-revealing names
- Use ubiquitous language in domain layer
- Pronounceable and searchable
- Class names: nouns (`Order`, `Customer`)
- Method names: verbs (`placeOrder`, `calculateTotal`)

**Red flags:**
| Bad | Why | Better |
|-----|-----|--------|
| `d`, `x`, `temp` | Not intention-revealing | `elapsedDays`, `position`, `processedOrder` |
| `data`, `info`, `item` | Too generic | `orderDetails`, `customerProfile`, `cartItem` |
| `mgr`, `ctrl`, `svc` | Abbreviated | `manager`, `controller`, `service` |
| `handleData()` | What does it handle? How? | `validateOrderData()`, `saveCustomerProfile()` |

### Functions

**Rules:**
| Rule | Guideline | Why |
|------|-----------|-----|
| Small | ~20 lines max | Easy to understand at a glance |
| Do one thing | Single level of abstraction | Easy to name, test, reuse |
| No side effects | If function queries, don't mutate | Predictable behavior |
| Few arguments | 0-2 ideal, 3+ needs object | Easy to call, test |

**Example:**
```typescript
// ❌ BAD: Multiple responsibilities, side effects
function processUser(userId: string): boolean {
  const user = db.query(`SELECT * FROM users WHERE id = ${userId}`); // SQL injection!
  if (!user.email.includes('@')) return false; // Query + validate
  user.lastLogin = new Date(); // + mutate
  db.save(user); // + persist
  emailService.send(user.email, 'Welcome back'); // + side effect
  return true;
}

// ✅ GOOD: Single responsibility, composed
function findUserById(userId: UserId): Promise<User | null> { /* ... */ }
function validateEmail(email: Email): boolean { /* ... */ }
function recordLogin(user: User): User { /* ... */ }
function sendWelcomeEmail(user: User): Promise<void> { /* ... */ }
```

### DRY (Don't Repeat Knowledge)

**What:** Don't repeat LOGIC/RULES, not just similar-looking code.

**Check:** If business rule changes, do you need to update multiple places? If yes → DRY violation.

**Not DRY:**
```typescript
// Two different concepts that happen to look similar
const orderTotal = items.reduce((sum, item) => sum + item.price, 0);
const taxAmount = taxRates.reduce((sum, rate) => sum + rate.amount, 0);
// Don't extract shared function - they solve different problems
```

**IS DRY:**
```typescript
// ❌ Same business rule in two places
function applyDiscount(price: number): number {
  return price * 0.9; // 10% discount
}

function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price * 0.9, 0); // Same 10% logic!
}

// ✅ Extract rule once
const DISCOUNT_RATE = 0.1;
function applyDiscount(price: number): number {
  return price * (1 - DISCOUNT_RATE);
}
```

### Error Handling

**Rules:**
- Use exceptions, not error codes
- Don't return `null` → use `Optional`/`Maybe`, throw, or return empty collection
- Fail fast (validate at boundary)
- Specific exceptions > generic ones

**Pattern:**
```typescript
// ❌ BAD: Returns null, caller must check
function findOrder(id: OrderId): Order | null {
  // ...
}

// ❌ BAD: Error codes
function placeOrder(command: PlaceOrderCommand): { success: boolean, error?: string } {
  // ...
}

// ✅ GOOD: Throws specific exception
function findOrder(id: OrderId): Order {
  const order = /* query */;
  if (!order) throw new OrderNotFoundError(id);
  return order;
}

// ✅ GOOD: Returns Optional
function findOrder(id: OrderId): Optional<Order> {
  // ...
}
```

### Single Level of Abstraction

**Rule:** Each function operates at ONE abstraction level. Don't mix high-level orchestration with low-level details.

**Example:**
```typescript
// ❌ BAD: Mixed abstraction levels
function processOrder(orderId: string) {
  const order = orders.find(orderId); // High-level

  // Suddenly low-level string manipulation
  const formattedId = orderId.substring(0, 8).toUpperCase() + '-' +
                      orderId.substring(8).toLowerCase();

  order.process(); // Back to high-level
}

// ✅ GOOD: Consistent abstraction level
function processOrder(orderId: OrderId) {
  const order = findOrder(orderId);
  const receipt = generateReceipt(order);
  sendConfirmation(order);
}

// Low-level details hidden in separate functions
function formatOrderId(raw: string): string {
  return raw.substring(0, 8).toUpperCase() + '-' + raw.substring(8).toLowerCase();
}
```

## Quick Reference Checklists

### Domain Layer Review
- [ ] No framework imports (no `@Entity`, `@Injectable`, etc.)
- [ ] No infrastructure types (no `UUID` from postgres, no HTTP types)
- [ ] Ubiquitous language only (no `data`, `info`, `manager`)
- [ ] Aggregates enforce invariants
- [ ] Value objects are immutable
- [ ] Entities have identity
- [ ] Repository interfaces in domain, implementations in infrastructure
- [ ] Domain events named in past tense

### Application Layer Review
- [ ] Use cases orchestrate domain logic
- [ ] Imports domain only (no infrastructure imports)
- [ ] Transaction boundaries clearly defined
- [ ] No business logic (delegate to domain)
- [ ] Depends on interfaces, not concrete classes

### Infrastructure Layer Review
- [ ] Implements domain interfaces (adapters for ports)
- [ ] Framework-specific code isolated here
- [ ] Database/API concerns never leak to domain
- [ ] ACL translates external models at boundary

### SOLID Violations Check
- [ ] Classes have single reason to change (SRP)
- [ ] Can add features without modifying existing code (OCP)
- [ ] Subtypes don't break parent contracts (LSP)
- [ ] No fat interfaces with unused methods (ISP)
- [ ] High-level depends on abstractions, not concrete implementations (DIP)

### Clean Code Check
- [ ] Names reveal intention
- [ ] Functions < 20 lines
- [ ] Functions do one thing
- [ ] No side effects in query functions
- [ ] Business rules not duplicated
- [ ] No null returns (use Optional/throw/empty collection)
- [ ] Exceptions, not error codes
- [ ] Single abstraction level per function
