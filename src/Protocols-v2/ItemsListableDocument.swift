//
//  ItemsListableDocument.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/24/26.
//

protocol ItemsListableDocument: RDDocument {
    var itemIds: Set<String> { set get }
}
