cube(`RecentTopGames`, {
  sql: `SELECT * FROM recent_top_games`,

  joins: {
    GameTags: {
      sql: `${CUBE}.app_id = ${GameTags.appId}`,
      relationship: `hasMany`
    },
    Genres: {
      sql: `${CUBE}.app_id = ${Genres.gameAppId}`,
      relationship: `hasMany`
    },
    Categories: {
      sql: `${CUBE}.app_id = ${Categories.gameAppId}`,
      relationship: `hasMany`
    }
  },

  measures: {
    count: {
      type: `count`,
      title: `Total Recent Top Games`
    },

    totalReviews: {
      sql: `COALESCE(total_positive, 0) + COALESCE(total_negative, 0)`,
      type: `sum`,
      title: `Total Reviews`
    },

    totalPositiveReviews: {
      sql: `total_positive`,
      type: `sum`,
      title: `Total Positive Reviews`
    },

    totalNegativeReviews: {
      sql: `total_negative`,
      type: `sum`,
      title: `Total Negative Reviews`
    }
  },

  dimensions: {
    appId: {
      sql: `app_id`,
      type: `number`,
      primaryKey: true,
      shown: true
    },

    name: {
      sql: `name`,
      type: `string`,
      title: `Game Name`
    },

    reviewScoreDesc: {
      sql: `review_score_desc`,
      type: `string`,
      title: `Review Description`
    },

    reviewScore: {
      sql: `review_score`,
      type: `number`,
      title: `Review Score`
    },

    lastUpdated: {
      sql: `last_updated`,
      type: `time`,
      title: `Last Updated`
    },

    releaseDate: {
      sql: `release_date_actual`,
      type: `time`,
      title: `Release Date`
    },

    isFree: {
      sql: `is_free`,
      type: `boolean`,
      title: `Is Free`
    }
  },

  segments: {
    veryPositiveOrBetter: {
      sql: `${CUBE}.review_score_desc IN ('Very Positive', 'Overwhelmingly Positive')`
    }
  },

  preAggregations: {
    main: {
      type: `rollup`,
      measures: [
        CUBE.count,
        CUBE.totalReviews,
        CUBE.totalPositiveReviews,
        CUBE.totalNegativeReviews
      ],
      dimensions: [
        CUBE.reviewScoreDesc
      ],
      refreshKey: {
        sql: `SELECT MAX(last_updated) FROM ${CUBE}`
      }
    }
  }
});


