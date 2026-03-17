# Fin Procedure YAML Format

Procedures are the core configuration primitive for Fin. They define step-by-step workflows that Fin follows when handling specific customer queries.

## Important: YAML Normalization

The API normalizes procedure steps on upload. Both formats are accepted for upload:

```yaml
# Upload format (explicit key)
procedure:
  main:
    - instructions: Ask the customer for their order number.

# Download format (normalized — what the API returns)
procedure:
  main:
    - Ask the customer for their order number.
```

When downloading a procedure, steps use the short form (`- "text"`) without the `instructions:` key. Both forms are valid for upload. When re-uploading a downloaded procedure, use it as-is.

## Minimal Procedure (New)

```yaml
name: Refund Policy
id: new
trigger_description: Customer asks about refunds or requests a refund
targeting:
  channels:
    - web
  audience: everyone
procedure:
  main:
    - instructions: Ask the customer for their order number.
    - instructions: Look up the order details.
    - instructions: >
        If the order is eligible for a refund, confirm the refund amount
        and process it. If not, explain the refund policy.
```

## Full Procedure (Downloaded from Workspace)

```yaml
id: 53500001
state: draft
version: 42542526
name: Refund Policy
trigger_description: Customer asks about refunds or requests a refund
targeting:
  channels:
    - web
    - mobile
  audience: everyone
temporary_attributes:
  order_number:
    type: string
    description: The customer's order number
  refund_eligible:
    type: boolean
    description: Whether the order is eligible for a refund
procedure:
  main:
    - instructions: Greet the customer and ask for their order number.
    - instructions: <write attr="order_number">the order number provided</write>
    - call_procedure: lookup_order
    - conditions:
        if:
          attribute: refund_eligible
          operator: is
          value: true
        then:
          - instructions: Confirm the refund and process it.
        else:
          - instructions: Explain that this order is not eligible for a refund per our policy.
    - instructions: Ask if there's anything else you can help with.

  lookup_order:
    - instructions: >
        Use the order_lookup data connector to fetch details for
        order <read attr="order_number" />.
    - instructions: <write attr="refund_eligible">whether the order is eligible based on the return window</write>
```

## Key Fields

### Top-Level Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name of the procedure |
| `id` | Yes | Set to `new` for creation, or the numeric ID for updates |
| `trigger_description` | Yes | When Fin should use this procedure — plain English description of the customer intent |
| `targeting.channels` | Yes | Array of channels: `web`, `mobile`, `email`, `sms` |
| `targeting.audience` | Yes | Who sees this: `everyone`, `users`, `leads` |
| `state` | No | `draft` or `live` (returned by API, usually don't set manually) |
| `version` | No | Version number (returned by API, required for updates to prevent conflicts) |
| `temporary_attributes` | No | Map of temporary variables scoped to this procedure |
| `procedure` | Yes | Map of procedure steps, must include `main` |

### Temporary Attributes

Variables scoped to the procedure execution. Defined as a map of name to definition:

```yaml
temporary_attributes:
  order_number:
    type: string
    description: The order number
  amount:
    type: decimal
    description: The refund amount
  items:
    type: list
    description: List of items in the order
  is_eligible:
    type: boolean
    description: Whether eligible for refund
```

Supported types: `string`, `boolean`, `decimal`, `list`

### Procedure Steps

The `procedure` field is a map where `main` is the entry point. Other keys are sub-procedures that can be called with `call_procedure`.

Each step in a procedure is one of:

#### Instructions
```yaml
- instructions: Plain text instructions for Fin to follow.
```

#### Read/Write Attributes
```yaml
# Read an attribute inline
- instructions: The customer's name is <read attr="user.first_name" />.

# Write to a temporary attribute
- instructions: <write attr="order_number">the order number the customer provided</write>
```

#### Call Sub-Procedure
```yaml
- call_procedure: lookup_order
```

#### Conditions
```yaml
- conditions:
    if:
      attribute: refund_eligible
      operator: is
      value: true
    then:
      - instructions: Process the refund.
    else:
      - instructions: Deny the refund.
```

Operators: `is`, `is_not`, `contains`, `does_not_contain`, `starts_with`, `ends_with`, `is_set`, `is_not_set`

#### Handoff
```yaml
- handoff:
    type: assign_conversation
    assignee_type: team
    assignee_id: "12345"
```

### Data Connector References

To use a data connector in a procedure, reference it by name in instructions:

```yaml
- instructions: >
    Use the order_lookup data connector to fetch the order details
    for order number <read attr="order_number" />.
```

The data connector must exist in the workspace (either live or draft).

## Simulation Test Format

Simulations are YAML files that test procedures:

```yaml
name: Happy Path - Refund Approved
description: Customer requests refund for eligible order
procedure_id: 53500001
messages:
  - role: customer
    content: Hi, I'd like to get a refund for my recent order
  - role: customer
    content: My order number is ORD-12345
assertions:
  - type: contains
    value: refund
  - type: does_not_contain
    value: unable
```

## Guidance Format

Guidance documents provide global instructions to Fin:

```yaml
name: Tone of Voice
category: general
audience: everyone
content: |
  Always be friendly and professional.
  Use the customer's first name when possible.
  Never use technical jargon.
  If unsure, offer to connect with a human agent.
```

## Common Patterns

### Multi-step with data connector
```yaml
procedure:
  main:
    - instructions: Ask for the order number.
    - instructions: <write attr="order_id">the order number</write>
    - instructions: Use the order_lookup connector to fetch order <read attr="order_id" />.
    - instructions: Summarize the order details to the customer.
```

### Escalation to human
```yaml
procedure:
  main:
    - instructions: Try to resolve the issue.
    - conditions:
        if:
          attribute: needs_human
          operator: is
          value: true
        then:
          - handoff:
              type: assign_conversation
              assignee_type: team
              assignee_id: "support-team-id"
        else:
          - instructions: Confirm the issue is resolved.
```

### Procedure with multiple sub-procedures
```yaml
procedure:
  main:
    - instructions: Determine what the customer needs help with.
    - conditions:
        if:
          attribute: intent
          operator: is
          value: refund
        then:
          - call_procedure: handle_refund
        else:
          - call_procedure: handle_general
  handle_refund:
    - instructions: Process the refund request.
  handle_general:
    - instructions: Provide general assistance.
```
