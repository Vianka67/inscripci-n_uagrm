import graphene
from .graphql.queries import Query
from .graphql.mutations import Mutation

schema = graphene.Schema(query=Query, mutation=Mutation)
