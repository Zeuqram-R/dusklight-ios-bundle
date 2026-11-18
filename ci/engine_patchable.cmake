# Give Dusklight's own engine code (UI, touch controls, input, achievements...) and RmlUi the
# same patchable function entries the game code already has. On iOS hooks are applied at build
# time and only functions with a patchable entry can be hooked; without this, mods that hook
# engine functions (e.g. Twilit Essentials) lose those features on iOS.
if (DUSK_ENABLE_CODE_MODS AND DEFINED DUSK_PATCHABLE_ENTRY_FLAG)
    foreach (_tgt dusk_internal rmlui_core RmlCore)
        if (TARGET ${_tgt})
            get_target_property(_imported ${_tgt} IMPORTED)
            get_target_property(_type ${_tgt} TYPE)
            if (NOT _imported AND NOT _type STREQUAL "INTERFACE_LIBRARY")
                target_compile_options(${_tgt} PRIVATE ${DUSK_PATCHABLE_ENTRY_FLAG})
                if (DUSK_GAME_ABI_INLINE_OPTIONS)
                    target_compile_options(${_tgt} PRIVATE ${DUSK_GAME_ABI_INLINE_OPTIONS})
                endif ()
                message(STATUS "Patchable entries enabled for ${_tgt}")
            endif ()
        endif ()
    endforeach ()
endif ()
