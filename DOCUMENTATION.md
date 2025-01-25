# DOCUMENTATION


## Tibber API
- [GraphQL Schema](https://developer.tibber.com/docs/reference)
- [Communication with the API and the GraphQL Endpoint](https://developer.tibber.com/docs/guides/calling-api)


### GraphQL Queries
**Energy price info for today and tomorrow:**

```graphql
  query get_current_prices{
    viewer {
      homes {
        currentSubscription {
          priceInfo {
            today {
              total
            }
            tomorrow {
              total
            }
          }
        }
      }
    }
  }
```
