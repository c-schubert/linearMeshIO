
export read_comsol_mphtxt

"""
    read_openfoam_mesh()

read, check, parse openfoam mesh
"""
function read_comsol_mphtxt(file_path::String)

    # boundary file should be ascii every time ...
    symbol_to_tokenID_dict, tokenID_to_symbol_dict, tokens = tokenize_ascii_file(file_path, "COMSOL_MPHTXT")
    # bf_preparse = parser(bf_tokens)
    # bf_parsed = dfs_parse(bf_preparse, bf_tokens)
    # meshinfo = getMeshInfo(bf_parsed, case_path)

    printtokens(tokens, tokenID_to_symbol_dict)
end