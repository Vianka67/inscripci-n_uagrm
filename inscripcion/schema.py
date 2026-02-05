import graphene
from .graphql.queries import Query

schema = graphene.Schema(query=Query)
