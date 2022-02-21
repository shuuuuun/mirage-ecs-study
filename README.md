# mirage-ecs study

with copilot.

### Refs.
* https://github.com/acidlemon/mirage-ecs
* https://github.com/fujiwara/mirage-ecs-example

### Versions
* mirage
  * `v0.6.6`
* copilot
  * `version: v1.13.0, built for darwin`

### Up
1. Set your domain to `BASE_DOMAIN` environment variable.
1. `make copilot/init`
1. `make copilot/deploy`
1. `make attach-role-policy`
1. Customize resources by manually...
    1. Remove a statement Deny iam:* in DenyIAMExceptTaggedRoles inline policy in TaskRole (e.g. role/mirage-ecs-study-dev-mirage-TaskRole-xxxxx).
    1. Add Route53 record set *.dev.mirage-ecs-study.example.com Alias to ALB (created by Copilot).
    1. Remove the host condition in the ALB listener rule, so that any host can access ECS.
1. Access mirage.dev.mirage-ecs-study.example.com.

### Down
1. Terminate all tasks in Mirage-ECS.
1. Remove Route53 record set *.dev.mirage-ecs-study.example.com.
1. `make copilot/delete`
