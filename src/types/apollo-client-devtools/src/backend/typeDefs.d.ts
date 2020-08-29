type TypeDefs = string | Record<string, unknown>

export interface Schema {
    definition: string,
    directives: string
}

export function buildSchemasFromTypeDefs(typeDefs: TypeDefs): [Schema]
