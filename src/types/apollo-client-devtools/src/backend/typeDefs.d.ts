type TypeDefs = string | {
    [key: string]: any
}

export interface Schema {
    definition: string,
    directives: string
}

export function buildSchemasFromTypeDefs(typeDefs: TypeDefs): [Schema]
