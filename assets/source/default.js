

function getFetchOptions() {
    return {
        method: 'GET',
        host: 'www.yhdmz.org',
        responseType: 'plain',
        contentType: 'text/html; charset=utf-8',
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
            '(KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.67',
    }
}

function createDocument(html) {
    const parser = new DOMParser()
    return parser.parseFromString(html, 'text/html')
}

/**
 * **必填方法**
 * 获取数据源信息
 * @returns {Map} {
 *         'key': '数据源唯一值，当与已有数据源重叠的时候会自动覆盖，可以使用英文名或缩写',
 *         'name': '数据源名称',
 *         'homepage': '数据源首页地址',
 *         'version': '版本号',
 *         'lastEditDate': '最后更新的时间戳，Iso8601格式',
 *         'logoUrl': '数据源图标在线地址',
 *     }
 */
async function getSourceInfo() {
    return {
        key: 'yhdmz',
        name: '樱花动漫',
        homepage: 'https://www.yhdmz.org',
        version: '1.0.0',
        lastEditDate: '2023-08-10T17:19:42.113727',
        logoUrl: 'https://www.yhdmz.org/tpsf/yh_pic/favicon.ico',
    };
}

/**
 * 获取番剧时间表
 * @returns {Map} {
 *         'monday': ['周一番剧列表'],
 *         'tuesday': ['周二番剧列表'],
 *         'wednesday': ['周三番剧列表'],
 *         'thursday': ['周四番剧列表'],
 *         'friday': ['周五番剧列表'],
 *         'saturday': ['周六番剧列表'],
 *         'sunday': ['周日番剧列表'],
 *     }
 */
async function getTimeTable() {
    let resp = await fetch('https://www.yhdmz.org', getFetchOptions())
    if (!resp.ok) throw new Error('请求失败,请重试')
    const doc = createDocument(resp.text())
    const selector = 'body > div.area > div.side.r > div.bg > div.tlist > ul'
    let tempList = []
    for (const ul in doc.querySelectorAll(selector)) {
        let temp = []
        for (const li in ul.querySelectorAll('li')) {
            const status = li.querySelectorAll('a')[0].textContent
            temp.add({
                'name': li.querySelectorAll('a')[1].textContent,
                'url': li.querySelectorAll('a')[1].href,
                'status': status.replaceAll('new', '').trim(),
                'isUpdate': status.contains('new'),
            });
        }
        tempList.push(temp)
    }
    return {
        'monday': tempList[0],
        'tuesday': tempList[1],
        'wednesday': tempList[2],
        'thursday': tempList[3],
        'friday': tempList[4],
        'saturday': tempList[5],
        'sunday': tempList[6],
    }
}

/**
 * 获取首页番剧列表的过滤条件(推荐写死到本配置内)
 * @returns {Array} [
 *     {
 *         'name': '过滤项名称',
 *         'key': '过滤项字段',
 *         'maxSelected': 最大可选数量(int),
 *         'items': [
 *              {
 *                  'name':'过滤项子项名称',
 *                  'value':'过滤项子项值'
 *              }
 *         ]
 *     }
 * ]
 */
async function loadFilterList() {
    return [{
        'name': '过滤项名称', 'key': '过滤项字段', 'maxSelected': 最大可选数量(int), 'items': [{
            'name': '过滤项子项名称', 'value': '过滤项子项值'
        }]
    }]
}

/**
 * 搜索番剧列表
 * @param {number} pageIndex 当前页码
 * @param {number} pageSize 当前页数据量
 * @param {string} keyword 搜索关键字
 * @returns {Array} [
 *         {
 *             'name': '过滤项名称',
 *             'key': '过滤项字段',
 *             'maxSelected': 最大可选数量(int),
 *             'items': [
 *                 {
 *                     'name': '过滤项子项名称',
 *                     'value': '过滤项子项值'
 *                 }
 *             ]
 *         }
 *     ]
 */
async function searchAnimeList(pageIndex, pageSize, keyword) {
    return [{
        'name': '过滤项名称', 'key': '过滤项字段', 'maxSelected': 最大可选数量(int), 'items': [{
            'name': '过滤项子项名称', 'value': '过滤项子项值'
        }]
    }]
}

/**
 * **必填方法**
 * 获取首页番剧列表
 * @param {number} pageIndex 当前页码
 * @param {number} pageSize 当前页数据量
 * @param {Map.<string,string>} filterSelect 用户选择的过滤条件(key：过滤项 value：过滤值)
 * @returns {Array} [
 *         {
 *             'name': '番剧名称',
 *             'cover': '番剧封面',
 *             'status': '当前状态（更新到xx集/已完结等）',
 *             'types': '番剧类型（武侠/玄幻这种）',
 *             'intro': '番剧介绍',
 *             'url': '番剧详情页地址'
 *         }
 *     ]
 */
async function loadHomeList(pageIndex, pageSize, filterSelect) {
    return [{
        'name': '番剧名称',
        'cover': '番剧封面',
        'status': '当前状态（更新到xx集/已完结等）',
        'types': '番剧类型（武侠/玄幻这种）',
        'intro': '番剧介绍',
        'url': '番剧详情页地址'
    }]
}

/**
 * **必填方法**
 * 获取番剧详情信息
 * @param {string} animeUrl 番剧详情页地址
 * @returns {Map} {
 *         'url': '番剧详情页地址',
 *         'name': '番剧名称',
 *         'cover': '番剧封面',
 *         'updateTime': '更新时间（不需要格式化）',
 *         'region': '地区',
 *         'types': '番剧类型（武侠/玄幻这种）',
 *         'status': '当前状态（更新到xx集/已完结等）',
 *         'intro': '番剧介绍',
 *         'resources': [
 *             [
 *                 {
 *                     'name': '资源名称',
 *                     'url': 'url资源地址（可以是目标页面的地址或者播放地址，在使用的时候会通过getPlayUrls结构进行转换）',
 *                     'order': 排序方式（int,推荐结构10001、10002，如果有多个资源使用前部结构区分）,
 *                 }
 *             ]
 *         ],
 *     }
 */
async function getAnimeDetail(animeUrl) {
    return {
        'url': '番剧详情页地址',
        'name': '番剧名称',
        'cover': '番剧封面',
        'updateTime': '更新时间（不需要格式化）',
        'region': '地区',
        'types': '番剧类型（武侠/玄幻这种）',
        'status': '当前状态（更新到xx集/已完结等）',
        'intro': '番剧介绍',
        'resources': [[{
            'name': '资源名称',
            'url': 'url资源地址（可以是目标页面的地址或者播放地址，在使用的时候会通过getPlayUrls结构进行转换）',
            'order': 1,
        }]],
    }
}

/**
 * **必填方法**
 * 根据资源地址转换为可播放/下载地址
 * 如果资源地址本身就是播放地址，也会调用此接口，直接返回即可
 * @param {Array.<string>} resourceUrls 资源地址列表(value：资源地址)
 * @returns {Map} [
 *         {
 *             'url': '资源地址（转换前）',
 *             'playUrl': '播放/下载地址（转换后）'
 *         }
 *     ]
 */
async function getPlayUrls(resourceUrls) {
    return [{
        'url': '资源地址（转换前）', 'playUrl': '播放/下载地址（转换后）'
    }]
}