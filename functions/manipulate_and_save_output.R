manipulate_and_save_output <- function(clusters_and_players, scores, model_parts, model_details, root, back_test, save, overwrite_date=NA){
  
  Date <- Sys.Date()
  if (is.na(overwrite_date)==FALSE){
    Date <- overwrite_date
  } 
  if (back_test==0){
    
     ft8 <- read.csv(paste0(root, "/rawdata/FiveThirtyEight_current.csv"), stringsAsFactors = FALSE) %>%
       rename(team=selected_team) %>%
       select(team, pred_win_rate_538)
     
     game_level <- data.frame(rbindlist(scores), stringsAsFactors = FALSE) %>% 
       select(-prob_selected_team_win_b) %>%
       mutate(d_pred_selected_team_win=ifelse(current_season_data_used==0, NA, as.numeric(prob_selected_team_win_d>0.5)),
           prob_selected_team_win=ifelse(current_season_data_used==0, NA, prob_selected_team_win_d))
     ranks <- report(game_level, "d_pred_selected_team_win") %>%
       left_join(conferences, by="team") %>%
       select(team, games_season, games_played, games_future, season_win_rate, ytd_win_rate, future_win_rate, conference, division) %>%
       left_join(ft8, by="team")
     models <- data.frame(rbindlist(model_details), stringsAsFactors = FALSE)
     parts <- data.frame(rbindlist(model_parts), stringsAsFactors = FALSE)
     details <- mutate(game_level, 
                    d_road_team_predicted_win=ifelse(is.na(d_pred_selected_team_win), NA, ifelse(selected_team==road_team_name, d_pred_selected_team_win, 1-d_pred_selected_team_win)), 
                    d_home_team_predicted_win=ifelse(is.na(d_pred_selected_team_win), NA, 1-d_road_team_predicted_win), 
                    predicted_winner=ifelse(is.na(d_pred_selected_team_win), "NA", ifelse(d_road_team_predicted_win==1, road_team_name, home_team_name)),
                    actual_winner=ifelse(is.na(selected_team_win), "NA", ifelse(selected_team_win==1, selected_team, opposing_team)),
                    home_team_prob_win=ifelse(is.na(d_pred_selected_team_win), NA, ifelse(selected_team==home_team_name, prob_selected_team_win_d, 1-prob_selected_team_win_d)), 
                    road_team_prob_win=ifelse(is.na(d_pred_selected_team_win), NA, 1-home_team_prob_win)) %>%
       mutate(predicted_winner=ifelse(future_game==0, "NA", predicted_winner), 
              d_road_team_predicted_win=ifelse(future_game==0, NA, d_road_team_predicted_win), 
              d_home_team_predicted_win=ifelse(future_game==0, NA, d_home_team_predicted_win), 
              home_team_prob_win=ifelse(future_game==0, NA, home_team_prob_win),
              road_team_prob_win=ifelse(future_game==0, NA, road_team_prob_win)) %>%
    select(DATE, home_team_name, road_team_name, road_team_prob_win, home_team_prob_win, predicted_winner, actual_winner, current_season_data_used, future_game)
       
    if (save==1){
      write.csv(ranks, paste0(root, "/rankings/rankings_",Date, ".csv"), row.names = FALSE)
      write.csv(details, paste0(root,"/rankings/game_level_predictions_",Date, ".csv"), row.names = FALSE)
      write.csv(clusters_and_players, paste0(root, "/modeldetails/cluster_details_",Date, ".csv"), row.names = FALSE)
      write.csv(models, paste0(root, "/modeldetails/coefficients_", Date, ".csv"), row.names = FALSE)
      write.csv(parts, paste0(root, "/modeldetails/score_decomp_", Date, ".csv"), row.names = FALSE)
    }
    return(list(game_level, ranks, models, details))
  } else{
    game_level <- data.frame(rbindlist(scores), stringsAsFactors = FALSE) %>% 
      select(-prob_selected_team_win_b) %>%
      mutate(prob_selected_team_win=ifelse(current_season_data_used==0, NA, prob_selected_team_win_d), 
             d_pred_selected_team_win=ifelse(current_season_data_used==0, NA, as.numeric(prob_selected_team_win>0.5)))
    ranks <- report(game_level, "d_pred_selected_team_win")
    models <- data.frame(rbindlist(model_details), stringsAsFactors = FALSE)
    return(list(game_level, ranks, models))
  }
}